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
        day_offset = slot_index // SLOTS_PER_DAY
        slot_in_day = slot_index % SLOTS_PER_DAY

        hour = MIN_HOUR + slot_in_day

        return start_of_today + timedelta(days=day_offset, hours=hour)

    for event_data in events_indices:
        participant_indices = event_data["participant_indices"]
        participant_ids = [user_ids[i] for i in participant_indices]

        start_time = slot_index_to_datetime(event_data["start_slot_index"])
        end_time = slot_index_to_datetime(event_data["end_slot_index"])

        ev = schemas.Event(
            id=0,
            game_name=f"Gra grupowa",
            from_time=start_time,
            to_time=end_time,
            participants=participant_ids
        )
        final_events.append(ev)

    print(f"Generated {len(final_events)} events from the schedule.")
    return final_events

def save_events_to_db(db: Session, events_to_create: List[schemas.Event]) -> None:
    created = 0
    updated = 0

    for event_schema in events_to_create:
        try:
            new_participants_set = set(event_schema.participants or [])
            if len(new_participants_set) < MIN_PLAYERS:
                print("Skipping event: less than MIN_PLAYERS.")
                continue

            from_t = event_schema.from_time
            to_t = event_schema.to_time

            conflicting_events = (
                db.query(models.Event)
                    .filter(models.Event.from_time < to_t,
                            models.Event.to_time > from_t)
                    .all()
            )

            busy_players = set()
            for ev in conflicting_events:
                busy_players.update(ev.participants or [])

            def has_conflict():
                return bool(new_participants_set & busy_players)

            existing_events = (
                db.query(models.Event)
                .filter(
                    models.Event.game_name == event_schema.game_name,
                    models.Event.from_time == event_schema.from_time,
                    models.Event.to_time == event_schema.to_time,
                )
                .all()
            )

            handled = False

            for ev in existing_events:
                existing_set = set(ev.participants or [])
                excluded_set = set(ev.excluded_participants or [])

                new_set = set(event_schema.participants or [])
                blocked = new_set & excluded_set
                if blocked:
                    print(f"Event {ev.id}: removing excluded participants: {blocked}")
                    new_set -= blocked

                if not new_set:
                    print(f"Event {ev.id}: new_set is empty after excluded filtering — skipping")
                    handled = True
                    break

                if new_set == existing_set:
                    print("Skipping duplicate event:", event_schema.game_name, event_schema.from_time)
                    handled = True
                    break

                if new_set.issubset(existing_set):
                    print("Skipping event because participants subset already exists.")
                    handled = True
                    break

                if new_set.issuperset(existing_set):
                    print(f"Updating event {ev.id} by adding participants:", list(new_set))
                    ev.participants = list(new_set)
                    db.add(ev)
                    updated += 1
                    handled = True
                    break

            if handled:
                continue

            if has_conflict():
                print("Cannot create a new event – players already assigned in this slot.")
                continue

            new_event = models.Event(
                game_name=event_schema.game_name,
                from_time=event_schema.from_time,
                to_time=event_schema.to_time,
                participants=list(new_participants_set),
                excluded_participants=[],
            )
            db.add(new_event)
            created += 1

        except Exception as e:
            db.rollback()
            print("Creation event error:", e)
            continue

    try:
        db.commit()
        print(f"Saved: {created} new events, {updated} updated.")
    except Exception as e:
        db.rollback()
        print("Error while saving events:", e)
