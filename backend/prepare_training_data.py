import random
from datetime import datetime, timedelta
import os
import json
import pytz
import numpy as np
from docplex.mp.model import Model

target_timezone = pytz.timezone("Europe/Warsaw")

number_of_simulations = 50
min_players = 4
max_players = 9
min_availabilities_per_user = 1
max_availabilities_per_user = 3
days = 7
time_slots_per_day = 7 # from 8:00 to 22:00 in 30-minute intervals
MIN_HOUR = 8
MAX_HOUR = 15

def generate_random_availabilities():
    """
    Gnerates random availabilities for a set of users.
    """

    num_users = random.randint(min_players, max_players)
    users_with_availabilities = {}

    print(f"Generowanie dostępności dla {num_users} uzytkowników")

    for i in range(num_users):
        user_id = f"user_{i+1}"
        users_with_availabilities[user_id] = []
        num_availabilities = random.randint(min_availabilities_per_user, max_availabilities_per_user)

        for _ in range(num_availabilities):
            random_day_offset = random.randint(0, days - 1)
            start_hour = random.randint(MIN_HOUR, MAX_HOUR - 2)
            
            duration_in_half_hours = random.randint(2, 8)
            duration_in_minutes = duration_in_half_hours * 30
            
            today = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
            start_time = today + timedelta(days=random_day_offset, hours=start_hour)
            
            if random.random() > 0.5:
                start_time = start_time.replace(minute=30)
            else:
                start_time = start_time.replace(minute=0)
                
            end_time = start_time + timedelta(minutes=duration_in_minutes)
            users_with_availabilities[user_id].append({"from": start_time, "to": end_time})

    print(f"Wygenerowano {sum(len(v) for v in users_with_availabilities.values())} dostępności.")
    return users_with_availabilities


def convert_availabilities_to_matrix(users_data: dict):

    all_users_ids = list(users_data.keys())
    number_of_users = len(all_users_ids)

    if number_of_users == 0:
        return None
    
    availability_matrix = [[[0] * time_slots_per_day for _ in range(days)] for _ in range(number_of_users)]
    max_games_per_user = [2] * number_of_users
    userid_index_map = {user_id: i for i, user_id in enumerate(all_users_ids)}

    start_of_today = datetime.now(target_timezone).replace(hour=0, minute=0, second=0, microsecond=0)

    for user_id, availabilities in users_data.items():
        player_index = userid_index_map[user_id]
        for availability in availabilities:

            from_time = availability["from"]
            to_time = availability["to"]

            from_time_local = target_timezone.localize(from_time) if from_time.tzinfo is None else from_time
            to_time_local = target_timezone.localize(to_time) if to_time.tzinfo is None else to_time

            delta_days = (from_time_local.date() - start_of_today.date()).days
            day_index = delta_days

            if 0 <= day_index < days:
                start_hour = from_time_local.hour
                start_minue = from_time_local.minute
                end_hour = to_time_local.hour
                end_minute = to_time_local.minute

                start_slot_index = (start_hour - MIN_HOUR) *2 + (1 if start_minue >= 30 else 0)
                end_slot_index = (end_hour - MIN_HOUR) * 2 + (1 if end_minute > 0 else 0)

                for slot_index in range(start_slot_index, end_slot_index):
                    if 0 <= slot_index < time_slots_per_day:
                        availability_matrix[player_index][day_index][slot_index] = 1

    input_data = {
        "iloscOsob": number_of_users,
        "maxGierDlaGracza": max_games_per_user,
        "dostepnosc": availability_matrix,
        "user_ids": all_users_ids
    }
    
    return input_data

def solve_with_cplex(input_data: dict):
    """
    Solves scheduling problem with CPLEX.
    """
    number_of_players = input_data["iloscOsob"]
    max_games = input_data["maxGierDlaGracza"]
    availability = input_data["dostepnosc"]
    min_players = 2
    max_players = 3

    mdl = Model(name= "Game Scheduler")
    players_games = mdl.binary_var_cube(range(number_of_players), range(days), range(time_slots_per_day), name="playersGames")
    games = mdl.binary_var_matrix(range(days), range(time_slots_per_day), name='games')

    mdl.maximize(mdl.sum(players_games[g, d, h] for g in range(number_of_players) for d in range(days) for h in range(time_slots_per_day)))

    # Ograniczenie 1: Dostępność gracza (dodawane RAZ)
    mdl.add_constraints(players_games[g, d, h] <= availability[g][d][h] for g in range(number_of_players) for d in range(days) for h in range(time_slots_per_day))

    # Ograniczenie 2: Liczba graczy w grze
    for d in range(days):
        for h in range(time_slots_per_day):
            mdl.add_constraint(mdl.sum(players_games[g, d, h] for g in range(number_of_players)) >= min_players * games[d, h])
            mdl.add_constraint(mdl.sum(players_games[g, d, h] for g in range(number_of_players)) <= max_players * games[d, h])
    
    # Ograniczenie 3: Powiązanie `gryGracza` z `gry` (dodawane RAZ)
    mdl.add_constraints(players_games[g, d, h] <= games[d, h] for g in range(number_of_players) for d in range(days) for h in range(time_slots_per_day))

    # Ograniczenie 4: Limit gier dla gracza (dodawane RAZ)
    mdl.add_constraints(mdl.sum(players_games[g, d, h] for d in range(days) for h in range(time_slots_per_day)) <= max_games[g] for g in range(number_of_players))
    
    print("Uruchamianie CPLEXa...")
    solution = mdl.solve()

    if solution:
        print("Znaleziono rozwiązanie.")
        scheduled_games = np.zeros(((number_of_players ,days, time_slots_per_day)))
        for g in range(number_of_players):
            for d in range(days):
                for h in range(time_slots_per_day):
                    scheduled_games[g, d, h] = solution.get_value(players_games[g, d, h])
        return scheduled_games
    else:
        print("Nie znaleziono rozwiązania.")


if __name__ == "__main__":
    
    SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
    RAW_DATA_DIR = os.path.join(SCRIPT_DIR, '..', 'training_data_raw')
    PROCESSED_DATA_DIR = os.path.join(SCRIPT_DIR, '..', 'processed_data')


    os.makedirs(RAW_DATA_DIR, exist_ok=True)
    os.makedirs(PROCESSED_DATA_DIR, exist_ok=True)
    
    for i in range(1, number_of_simulations + 1):
        availabilities_dict = generate_random_availabilities()

        file_path = os.path.join(RAW_DATA_DIR, f"simulation_{i}.json")
        with open(file_path, 'w') as f:
            json.dump(availabilities_dict, f, indent=2, default=str)
        print(f"Zapisano symulację do: {file_path}")

        input_matrix_data = convert_availabilities_to_matrix(availabilities_dict)
        if input_matrix_data:
            output = solve_with_cplex(input_matrix_data)
            processed_file_path = os.path.join(PROCESSED_DATA_DIR, f"simulation_{i}_processed.npz")
            np.savez_compressed(
                processed_file_path,
                x=np.array(input_matrix_data["dostepnosc"]),
                y=output
            )
            print(f"Zapisano parę treningową do: {processed_file_path}")
    
        
    print(f"\nZakończono. Wygenerowano {number_of_simulations} plików z symulacjami w folderze 'training_data_raw'.")