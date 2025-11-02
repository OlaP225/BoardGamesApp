import numpy as np
from datetime import datetime, timedelta, timezone
from . import schemas, models
from sqlalchemy.orm import Session
from app.config import *
from typing import List

def translate_schedule_to_events(schedule_per_player: np.ndarray, user_ids: List[str]):
    """
    Creates a list of schemas.Event based on the provided schedule matrix.
    """

    open_games = {}
    events_indices = []

    players, days, slots = schedule_per_player.shape
    schedule_by_slot = schedule_per_player.transpose(1, 2, 0).reshape(days * slots, players)
    MIN_P = MIN_PLAYERS

    for slot_index in range(schedule_by_slot.shape[0]):
        current_players_indices = np.where(schedule_by_slot[slot_index] == 1)[0]

        if len(current_players_indices) < MIN_P:
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

    final_events: List[schemas.Event] = []
    start_of_today = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)

    def slot_index_to_datetime(slot_index: int):
        """
        Converts a slot index to a UTC datetime object.
        """
        day_offset = slot_index // SLOTS_PER_DAY
        slot_in_day = slot_index % SLOTS_PER_DAY

        if slot_in_day == 0 and slot_index > 0:
            day_offset -= 1
            slot_in_day = SLOTS_PER_DAY

        hour = MIN_HOUR + slot_in_day
        event_date = start_of_today + timedelta(days=day_offset)
        return event_date.replace(hour=hour, minute=0, second=0, microsecond=0)

    for event_data in events_indices:
        participant_indices = event_data["participant_indices"]
        participant_ids = [user_ids[i] for i in participant_indices]

        start_time = slot_index_to_datetime(event_data["start_slot_index"])
        end_time = slot_index_to_datetime(event_data["end_slot_index"])

        ev = schemas.Event(
            id=0,
            game_name="Wylosowana Gra",
            from_time=start_time,
            to_time=end_time,
            status="pending",
            participants=participant_ids
        )
        final_events.append(ev)

    print(f"Generated {len(final_events)} events from the schedule.")
    return final_events

def save_events_to_db(db: Session, events_to_create: List[schemas.Event]):
    """
    Saves the provided list of schemas.Event to the database.
    """
    try:
        old_pending = db.query(models.Event).filter(models.Event.status == "pending").all()
        if old_pending:
            for ev in old_pending:
                db.delete(ev)
            db.commit()
            print(f"Deleted {len(old_pending)} old pending events.")
    except Exception as e:
        db.rollback()
        print("Warning: not possible to delete old pending events:", e)

    created = 0
    for event_schema in events_to_create:
        try:
            new_event = models.Event(
                game_name=event_schema.game_name,
                from_time=event_schema.from_time,
                to_time=event_schema.to_time,
                status=getattr(event_schema, "status", "pending")
            )
            db.add(new_event)
            db.flush()

            participant_user_ids = event_schema.participants or []
            if participant_user_ids:
                users = db.query(models.User).filter(models.User.userID.in_(participant_user_ids)).all()

                if hasattr(new_event, "participants"):
                    try:
                        new_event.participants = users
                    except Exception:
                        try:
                            for u in users:
                                new_event.participants.append(u)
                        except Exception:
                            pass
                elif hasattr(models, "EventParticipant"):
                    for u in users:
                        ep = models.EventParticipant(
                            user_id=getattr(u, "userID", None) or getattr(u, "id", None),
                            event_id=new_event.id,
                            status="pending"
                        )
                        db.add(ep)
                else:
                    print("Warning: lack of participants relationship or EventParticipant model.")
            created += 1

        except Exception as e:
            print("Creation event error:", e)
            db.rollback()
            continue

    try:
        db.commit()
        print(f"Succesfully saved {created} new games.")
    except Exception as e:
        db.rollback()
        print("Error while saving events to database:", e)
