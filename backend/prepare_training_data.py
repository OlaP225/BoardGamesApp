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
min_availabilities_per_user = 3
max_availabilities_per_user = 6
MIN_HOUR = 10
MAX_HOUR = 20

def generate_random_availabilities():
    """
    Gnerates random availabilities for a set of users. Function returns a dictionary in a format:
    {"user_1": [{"from": "2023-10-01T10:00:00", "to": "2023-10-01T12:00:00"}, ...], "user_2": etc ...}       
    """

    num_users = random.randint(min_players_sim, max_players_sim)
    users_with_availabilities = {}

  ##  print(f"Generating availability for {num_users} users...")

    for i in range(num_users):
        user_id = f"user_{i+1}"
        users_with_availabilities[user_id] = {
            "availabilities": [],
            "prefs": []
        }
        num_availabilities = random.randint(min_availabilities_per_user, max_availabilities_per_user)

        while True:
            pref = [1 if random.random() < 0.3 else 0 for _ in range(5)]
            if any(pref):
                break
        users_with_availabilities[user_id]["prefs"] = pref        

        for _ in range(num_availabilities):
            random_day_offset = random.randint(0, DAYS_IN_SCHEDULE - 1)
            start_hour = random.randint(MIN_HOUR, MAX_HOUR - 1)
            
            duration_in_hours = random.randint(1,4)
            
            today_utc = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
            start_time_utc = today_utc + timedelta(days=random_day_offset, hours=start_hour)
                
            end_time_utc = start_time_utc + timedelta(hours=duration_in_hours)
            if end_time_utc.hour > MAX_HOUR:
                end_time_utc = end_time_utc.replace(hour=MAX_HOUR)
            users_with_availabilities[user_id]["availabilities"].append({"from": start_time_utc, "to": end_time_utc})

  ##  print(f"There were  {sum(len(v) for v in users_with_availabilities.values())} availabilities generated.")
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

    for user_id, data in users_data.items():
        player_index = userid_index_map[user_id]
        availabilities = data.get("availabilities", [])
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
    prefs_vectors = []
    for user_id in all_users_ids:
        pref = users_data[user_id].get("prefs", [0]*5)
        prefs_vectors.append(pref)

    input_data = {
        "iloscOsob": number_of_users,
        "maxGierDlaGracza": max_games_per_user,
        "dostepnosc": availability_matrix,
        "user_ids": all_users_ids,
        "prefs": prefs_vectors
    }
 #   print(input_data["dostepnosc"])
    return input_data

def solve_with_cplex(input_data: dict):
 
    number_of_players = input_data["iloscOsob"]
 #   max_games = input_data["maxGierDlaGracza"]
    availability = np.array(input_data["dostepnosc"])
    prefs = np.array(input_data.get("prefs", [[[0]*5] for _ in range(number_of_players)]), dtype=int)
    min_players_num = 2
    max_players_num = 4
    num_tags = prefs.shape[1]

    mdl = Model(name= "Game Scheduler")
    players_games = mdl.binary_var_cube(range(number_of_players), range(DAYS_IN_SCHEDULE), range(SLOTS_PER_DAY), name="playersGames")
    games = mdl.binary_var_matrix(range(DAYS_IN_SCHEDULE), range(SLOTS_PER_DAY), name='games')

    y = mdl.binary_var_cube(range(DAYS_IN_SCHEDULE), range(SLOTS_PER_DAY), range(num_tags), name="tag_present")

    mdl.maximize(mdl.sum(players_games[p, d, h] for p in range(number_of_players) for d in range(DAYS_IN_SCHEDULE) for h in range(SLOTS_PER_DAY)))

    # Constraint 1: Player has a game only when they are available
    mdl.add_constraints(players_games[p, d, h] <= availability[p][d][h] for p in range(number_of_players) for d in range(DAYS_IN_SCHEDULE) for h in range(SLOTS_PER_DAY))


    # Constraint 2: Game will happen only if there are enough players (for now min 2, max 4)
    for d in range(DAYS_IN_SCHEDULE):
        for h in range(SLOTS_PER_DAY):
            mdl.add_constraint(mdl.sum(players_games[p, d, h] for p in range(number_of_players)) >= min_players_num * games[d, h])
            mdl.add_constraint(mdl.sum(players_games[p, d, h] for p in range(number_of_players)) <= max_players_num * games[d, h])

    # Constraint 3: Each player can't play more times than their max allowed games.
 #  mdl.add_constraints(mdl.sum(players_games[p, d, h] for d in range(DAYS_IN_SCHEDULE) for h in range(SLOTS_PER_DAY)) <= max_games[p] for p in range(number_of_players))

    # A) Jeśli y[d,h,t] == 1 to co najmniej 2 przypisanych graczy mają pref p,t
    for d in range(DAYS_IN_SCHEDULE):
        for h in range(SLOTS_PER_DAY):
            for t in range(num_tags):
                mdl.add_constraint(
                    mdl.sum(players_games[p, d, h] * int(prefs[p, t]) for p in range(number_of_players))
                    >= 2 * y[d, h, t]
                )

    # B) Jeśli nie ma żadnego aktywnego taga (sum_t y == 0) to w slocie nie może być >=2 graczy.
    #    Implementacja liniowa: sum_players - 1 <= max_players_num * sum_t_y
    #    (jeśli sum_t_y==0 => sum_players <= 1; jeśli sum_t_y>=1 => brak dodatkowego ograniczenia)
    for d in range(DAYS_IN_SCHEDULE):
        for h in range(SLOTS_PER_DAY):
            sum_players_expr = mdl.sum(players_games[p, d, h] for p in range(number_of_players))
            sum_y_expr = mdl.sum(y[d, h, t] for t in range(num_tags))
            mdl.add_constraint(sum_players_expr - 1 <= max_players_num * sum_y_expr)





    
    print("Starting CPLEX calculations...")
    solution = mdl.solve()

    if solution:
  #      print("Solution found.")
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

            # --- DEBUG: show availability matrix, prefs and result before saving ---
            x_arr = np.array(input_matrix_data["dostepnosc"])  # shape: (players, days, slots)
            prefs_arr = np.array(input_matrix_data.get("prefs", [[0]*5 for _ in range(len(x_arr))]))
            maxgames_arr = np.array(input_matrix_data["maxGierDlaGracza"])
            y_arr = np.array(output) if output is not None else None

            print("\n--- DEBUG OUTPUT ---")
            print(f"Simulation #{i}")
            print(f"Availability matrix shape (players, days, slots): {x_arr.shape}")
            # print full availability matrix (player by player) in readable way
            for p_idx in range(x_arr.shape[0]):
                print(f" Player {p_idx} availability (days x slots):")
                print(x_arr[p_idx].tolist())
            print(f"\nPrefs vectors shape: {prefs_arr.shape}")
            for p_idx in range(prefs_arr.shape[0]):
                print(f" Player {p_idx} prefs: {prefs_arr[p_idx].tolist()}")
            if y_arr is not None:
                print(f"\nCPLex scheduled_games shape (players, days, slots): {y_arr.shape}")
                # print schedule per player
                for p_idx in range(y_arr.shape[0]):
                    print(f" Player {p_idx} scheduled (days x slots):")
                    print(y_arr[p_idx].astype(int).tolist())

            processed_file_path = os.path.join(PROCESSED_DATA_DIR, f"simulation_{i}_processed.npz")
            np.savez_compressed(
                processed_file_path,
                x=np.array(input_matrix_data["dostepnosc"]),
                y=output,
                maxGames = np.array(input_matrix_data["maxGierDlaGracza"]),
                prefs = prefs_arr
            )
            print(f"Final package with simulated availabilities data and cplex output representing arranged schedule saved to: {processed_file_path}")
    
        
    print(f"\Fninished. There are {number_of_simulations} files generated with simulations and cplex results.")