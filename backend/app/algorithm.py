import numpy as np
from datetime import datetime, timedelta
import pytz
from . import schemas, models
from sqlalchemy.orm import Session
from app.config import *

def translate_schedule_to_events(schedule_per_player, user_ids, target_timezone_str="Europe/Warsaw"):
    target_timezone = pytz.timezone(target_timezone_str)
    open_games = {}
    events_indices = []

    schedule_by_slot = schedule_per_player.T
    for slot_index in range(len(schedule_by_slot)):
        current_players_indices = np.where(schedule_by_slot[slot_index] == 1)[0]
        if len(current_players_indices) < MIN_PLAYERS:
            current_players_indices = []

        if len(current_players_indices) == 0:
            if open_games:
                events_indices.extend(open_games.values())
                open_games = {} 
            continue

        current_group_key = tuple(sorted(current_players_indices))
        if current_group_key in open_games:
            open_games[current_group_key]['end_slot_index'] = slot_index + 1
        else:
            if open_games:
                events_indices.extend(open_games.values())
                
            open_games = {
                current_group_key: {
                    "start_slot_index": slot_index,
                    "end_slot_index": slot_index + 1,
                    "participant_indices": list(current_group_key)
                }
            }

    if open_games:
        events_indices.extend(open_games.values())

    final_events = []
    start_of_today = datetime.now(target_timezone).replace(hour=0, minute=0, second=0, microsecond=0)

    for event_data in events_indices:


        def slot_index_to_datetime(slot_index):
            day_offset = slot_index // SLOTS_PER_DAY
            slot_in_day = slot_index % SLOTS_PER_DAY
            
            hour = MIN_HOUR + slot_in_day

            
            event_date = start_of_today + timedelta(days=day_offset)
            event_datetime = event_date.replace(hour=hour, minute=0, second=0)
            
            return event_datetime

        participant_ids = [user_ids[i] for i in event_data["participant_indices"]]

        start_time = slot_index_to_datetime(event_data["start_slot_index"])
        end_time = slot_index_to_datetime(event_data["end_slot_index"])

        final_events.append(schemas.Event(
            id=0,
            game_name="Wylosowana Gra",
            from_time=start_time,
            to_time=end_time,
            status= "pending",
            participants= participant_ids
        ))

    print(f"Generated {len(final_events)} events from the schedule.")
    return final_events

def save_events_to_db(db: Session, events_to_create: list[schemas.Event]):
    old_pending_events = db.query(models.Event).filter(models.Event.status == "pending").all()
    if old_pending_events:
        for event in old_pending_events:
            db.delete(event)


    for event_data in events_to_create:
        new_event = models.Event(
            game_name=event_data.game_name,
            from_time=event_data.from_time,
            to_time=event_data.to_time
        )
        participant_user_ids = event_data.participants
        participant_objects = db.query(models.User).filter(models.User.userID.in_(participant_user_ids)).all()
        new_event.participants = participant_objects

        db.add(new_event)
    
    try:
        db.commit()
        print(f"Pomyślnie zapisano {len(events_to_create)} nowych, proponowanych wydarzeń.")
    except Exception as e:
        print(f"BŁĄD podczas zapisu wydarzeń do bazy: {e}")
        db.rollback()

                            
    
    


