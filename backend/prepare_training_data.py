import random
from datetime import datetime, timedelta, timezone
import os
import json
import numpy as np
from docplex.mp.model import Model
from app.config import *

number_of_simulations = 500
min_players_sim = 2
max_players_sim = 6
min_availabilities_per_user = 10
max_availabilities_per_user = 20
MIN_HOUR = 10
MAX_HOUR = 20

def generate_random_availabilities():
    """
    Gnerates random availabilities for a set of users. Function returns a dictionary in a format:
    {"user_1": [{"from": "2023-10-01T10:00:00", "to": "2023-10-01T12:00:00"}, ...], "user_2": etc ...}       
    """

    num_users = random.randint(min_players_sim, max_players_sim)
    users_with_availabilities = {}

    print(f"Generating availability for {num_users} users...")

    for i in range(num_users):
        user_id = f"user_{i+1}"
        users_with_availabilities[user_id] = []
        num_availabilities = random.randint(min_availabilities_per_user, max_availabilities_per_user)

        for _ in range(num_availabilities):
            random_day_offset = random.randint(0, DAYS_IN_SCHEDULE - 1)
            start_hour = random.randint(MIN_HOUR, MAX_HOUR - 1)
            
            duration_in_hours = random.randint(1,4)
            
            today_utc = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
            start_time_utc = today_utc + timedelta(days=random_day_offset, hours=start_hour)
                
            end_time_utc = start_time_utc + timedelta(hours=duration_in_hours)
            if end_time_utc.hour > MAX_HOUR:
                end_time_utc = end_time_utc.replace(hour=MAX_HOUR)
            users_with_availabilities[user_id].append({"from": start_time_utc, "to": end_time_utc})

    print(f"There were  {sum(len(v) for v in users_with_availabilities.values())} availabilities generated.")
    return users_with_availabilities


def convert_availabilities_to_matrix(users_data: dict):

    all_users_ids = list(users_data.keys())
    number_of_users = len(all_users_ids)

    if number_of_users == 0:
        return None
    
    availability_matrix = [[[0] * SLOTS_PER_DAY for _ in range(DAYS_IN_SCHEDULE)] for _ in range(number_of_users)]
    max_games_per_user = [2] * number_of_users
    userid_index_map = {user_id: i for i, user_id in enumerate(all_users_ids)}

    start_of_today_utc = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)

    for user_id, availabilities in users_data.items():
        player_index = userid_index_map[user_id]
        for availability in availabilities:

            from_time_utc = availability["from"]
            to_time_utc = availability["to"]

            delta_days = (from_time_utc.date() - start_of_today_utc.date())
            day_index = delta_days.days

            if 0 <= day_index < DAYS_IN_SCHEDULE:
                start_hour = from_time_utc.hour
                end_hour = to_time_utc.hour

                start_slot_index = start_hour - MIN_HOUR
                end_slot_index = end_hour - MIN_HOUR

                for slot_index in range(start_slot_index, end_slot_index):
                    if 0 <= slot_index < SLOTS_PER_DAY:
                        availability_matrix[player_index][day_index][slot_index] = 1

    input_data = {
        "iloscOsob": number_of_users,
        "maxGierDlaGracza": max_games_per_user,
        "dostepnosc": availability_matrix,
        "user_ids": all_users_ids
    }
    
    return input_data

def solve_with_cplex(input_data: dict):
 
    number_of_players = input_data["iloscOsob"]
    max_games = input_data["maxGierDlaGracza"]
    availability = np.array(input_data["dostepnosc"])
    min_players_num = 2
    max_players_num = 4

    mdl = Model(name= "Game Scheduler")
    players_games = mdl.binary_var_cube(range(number_of_players), range(DAYS_IN_SCHEDULE), range(SLOTS_PER_DAY), name="playersGames")
    games = mdl.binary_var_matrix(range(DAYS_IN_SCHEDULE), range(SLOTS_PER_DAY), name='games')

    mdl.maximize(mdl.sum(players_games[p, d, h] for p in range(number_of_players) for d in range(DAYS_IN_SCHEDULE) for h in range(SLOTS_PER_DAY)))

    # Constraint 1: Player has a game only when they are available
    mdl.add_constraints(players_games[p, d, h] <= availability[p][d][h] for p in range(number_of_players) for d in range(DAYS_IN_SCHEDULE) for h in range(SLOTS_PER_DAY))


    # Constraint 2: Game will happen only if there are enough players (for now min 2, max 4)
    for d in range(DAYS_IN_SCHEDULE):
        for h in range(SLOTS_PER_DAY):
            mdl.add_constraint(mdl.sum(players_games[p, d, h] for p in range(number_of_players)) >= min_players_num * games[d, h])
            mdl.add_constraint(mdl.sum(players_games[p, d, h] for p in range(number_of_players)) <= max_players_num * games[d, h])

    # Constraint 3: Each player can't play more times than their max allowed games.
    mdl.add_constraints(mdl.sum(players_games[p, d, h] for d in range(DAYS_IN_SCHEDULE) for h in range(SLOTS_PER_DAY)) <= max_games[p] for p in range(number_of_players))
    
    print("Starting CPLEX calculations...")
    solution = mdl.solve()

    if solution:
        print("Solution found.")
        scheduled_games = np.zeros(((number_of_players ,DAYS_IN_SCHEDULE, SLOTS_PER_DAY)))
        for p in range(number_of_players):
            for d in range(DAYS_IN_SCHEDULE):
                for h in range(SLOTS_PER_DAY):
                    scheduled_games[p, d, h] = solution.get_value(players_games[p, d, h])
        return scheduled_games
    else:
        print("No solution found")


if __name__ == "__main__":
    
    SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
    RAW_DATA_DIR = os.path.join(SCRIPT_DIR, '..', 'cplex_training_data')
    PROCESSED_DATA_DIR = os.path.join(SCRIPT_DIR, '..', 'cplex_processed_data')


    os.makedirs(RAW_DATA_DIR, exist_ok=True)
    os.makedirs(PROCESSED_DATA_DIR, exist_ok=True)
    
    for i in range(1, number_of_simulations + 1):
        availabilities_dict = generate_random_availabilities()

        file_path = os.path.join(RAW_DATA_DIR, f"simulation_{i}.json")
        with open(file_path, 'w') as f:
            json.dump(availabilities_dict, f, indent=2, default=str)
        print(f"Simulation saved to: {file_path}")

        input_matrix_data = convert_availabilities_to_matrix(availabilities_dict)
        if input_matrix_data:
            output = solve_with_cplex(input_matrix_data)
            print(f"Cplex solution for simulation number {i}:\n{output}") ##test
            processed_file_path = os.path.join(PROCESSED_DATA_DIR, f"simulation_{i}_processed.npz")
            np.savez_compressed(
                processed_file_path,
                x=np.array(input_matrix_data["dostepnosc"]),
                y=output,
                maxGames = np.array(input_matrix_data["maxGierDlaGracza"])
            )
            print(f"Final package with simulated availabilities data and cplex output representing arranged schedule saved to: {processed_file_path}")
    
        
    print(f"\Fninished. There are {number_of_simulations} files generated with simulations and cplex results.")