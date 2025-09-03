import random
from datetime import datetime, timedelta
import os
import json

number_of_simulations = 50
min_players = 4
max_players = 9
min_availabilities_per_user = 1
max_availabilities_per_user = 5
days = 30
time_slots_per_day = 28 # from 8:00 to 22:00 in 30-minute intervals
MIN_HOUR = 8
MAX_HOUR = 22

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

if __name__ == "__main__":
    
    SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
    RAW_DATA_DIR = os.path.join(SCRIPT_DIR, '..', 'training_data_raw')

    os.makedirs(RAW_DATA_DIR, exist_ok=True)
    
    for i in range(1, number_of_simulations + 1):
        availabilities = generate_random_availabilities()

        file_path = os.path.join(RAW_DATA_DIR, f"simulation_{i}.json")
        with open(file_path, 'w') as f:
            json.dump(availabilities, f, indent=2, default=str)
        print(f"Zapisano symulację do: {file_path}")
        
    print(f"\nZakończono. Wygenerowano {number_of_simulations} plików z symulacjami w folderze 'training_data_raw'.")
