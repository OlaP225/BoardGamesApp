from sqlalchemy.orm import Session
from datetime import datetime, time
from . import models
import pytz
from app.config import *

target_timezone = pytz.timezone("Europe/Warsaw")
local_now = datetime.now(target_timezone)
start_of_day = local_now.replace(hour=0, minute=0, second=0, microsecond=0)
days_in_schedule = 7 
slots_per_day = 10 

def prepare_input_data(db: Session):
    """
    Function takes data of all users and their availabilities from database and converts it to 
    matrixes for matchmaking algorithm. Each user is represented by a matrix of all time slots
    with 1 (available) or 0 (unavailable).
    """
    all_users = db.query(models.User).filter(models.User.availabilities.any()).all()
    if not all_users:
        print("No users with availabilities found. Unable to prepare input data for matchmaking.")
        return None
    availability_matrix = [[[0] * slots_per_day for _ in range(days_in_schedule)] for _ in range(len(all_users))]
    max_games_per_user = [2] * len(all_users)
    userid_index_map = {user.userID: i for i, user in enumerate(all_users)}

    for user in all_users:
        player_index = userid_index_map[user.userID]
        if player_index is None:
            continue
        for availability in user.availabilities:

            from_time_utc = pytz.utc.localize(availability.from_time)
            to_time_utc = pytz.utc.localize(availability.to_time)

            from_time_local = from_time_utc.astimezone(target_timezone)
            to_time_local =  to_time_utc.astimezone(target_timezone)

            delta_days = (from_time_local.date() - start_of_day.date()).days
            day_index = delta_days

            if 0 <= day_index < days_in_schedule:
                start_hour = from_time_local.hour
                end_hour = to_time_local.hour

                start_slot_index = start_hour - MIN_HOUR
                end_slot_index = end_hour - MIN_HOUR

                for slot_index in range(start_slot_index, end_slot_index):
                    if 0 <= slot_index < slots_per_day:
                        availability_matrix[player_index][day_index][slot_index] = 1




    input_data = {
        "iloscOsob": len(all_users),
        "maxGierDlaGracza": max_games_per_user,
        "dostepnosc": availability_matrix,
        "user_ids": [user.userID for user in all_users]
        
    }
    print("Pomyślnie przygotowano dane wejściowe dla algorytmu.")
    return input_data
