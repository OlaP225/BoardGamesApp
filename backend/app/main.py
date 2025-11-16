from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from . import models, schemas
from .database import SessionLocal, engine
from .matchmaking import prepare_input_data, run_gnn_prediction
import numpy as np
import torch
from .config import *
import os
import sys
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from create_gnn_model import GNN
from . import save_games
from .schemas import LeaveEventRequest
from fastapi import Body
models.Base.metadata.create_all(bind=engine)

app = FastAPI()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/")
def read_root():
    return {"message": "Serwer BoardGamesApp is working!"}

@app.post("/api/users", response_model=schemas.User)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user_existing = db.query(models.User).filter(models.User.userID == user.userID).first()
    if db_user_existing:
        raise HTTPException(status_code=400, detail="User with this ID already exists!")
    db_user = models.User(userID = user.userID, username = user.username, preferences = user.preferences)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    #test

    db_user_test = db.query(models.User).filter(models.User.userID == user.userID).first()
    if db_user_test:
        print("Checking availability of user:", db_user_test.username)
        for slot in db_user_test.availabilities:
            print(f"  Availability: {slot.from_time} - {slot.to_time}")


    #test

    print(f"Created user: {db_user.userID}, {db_user.username}")
    return db_user

@app.post("/api/users/{user_id}/availabilities", response_model=schemas.Availability)
def create_availability_for_user(user_id: str, availability: schemas.AvailabilityCreate, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.userID == user_id).first()
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    db_availability = models.Availability(
        from_time = availability.from_time,
        to_time = availability.to_time,
        owner_id = user_id
    )
    db.add(db_availability)
    db.commit()
    db.refresh(db_availability)
    print(f"Availability saved for user {user_id}: {db_availability.from_time} - {db_availability.to_time}")
    return db_availability

@app.delete("/api/availabilities/{availability_id}", status_code=204)
def delete_availability(availability_id: int, db: Session = Depends(get_db)):
    db_availability = db.query(models.Availability).filter(models.Availability.id == availability_id).first()
    if db_availability is None:
        raise HTTPException(status_code=404, detail="Availability not found")
    db.delete(db_availability)
    db.commit()
    print(f"Removed availability with ID: {availability_id}")
    return



@app.get("/api/users/{user_id}/availabilities", response_model=list[schemas.Availability])
def read_availabilities_for_user(user_id: str, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.userID == user_id).first()
    if db_user is None:
        raise HTTPException(status_code=404, detail="User not found")
    return db_user.availabilities


global_gnn_model = None

@app.on_event("startup")
def load_model():
    global global_gnn_model
    model_path = os.path.join(os.path.dirname(__file__), "gnn_model.pth")
    if not os.path.exists(model_path):
        print(f"Error: There is no file under path {model_path}")
        return
    
    print(f"Loading GNN model...")
    model = GNN(in_features=PLAYERS_CONSTANT, hidden=128, out_features=PLAYERS_CONSTANT)
    model.load_state_dict(torch.load(model_path, map_location=torch.device('cpu')))
    model.eval()
    print("GNN model loaded and ready for predictions.")

    global_gnn_model = model


@app.post("/api/matchmaking/run")
def run_matchmaking(db: Session = Depends(get_db)):
    print("\n\n Matchmaking started ... ")

    if global_gnn_model is None:
        raise HTTPException(status_code=503, detail="GNN model is not loaded.")
    
    input_data = prepare_input_data(db)
    if input_data is None:
        print("Finished matchmaking - no availabilities to process. ")
        return {"message": "No availabilities found to process."}

    print("Model and availabilities are ready, running GNN prediction...")
    print(input_data)

    result_matrix = run_gnn_prediction(global_gnn_model, input_data)

    print(result_matrix)

    translated_events = save_games.translate_schedule_to_events(
        schedule_per_player=result_matrix,
        user_ids=input_data.user_ids
    )
    print("Translated events:", translated_events)
    
    save_games.save_events_to_db(db, translated_events)

    print("GNN prediction finished \n")
    return {"status": "success", "message": "Matchmaking completed and events saved."}

@app.get("/api/users/{user_id}/events", response_model=list[schemas.Event])
def get_user_events(user_id: str, db: Session = Depends(get_db)):
    events = db.query(models.Event).filter(models.Event.participants.contains([user_id])).all()

    result = []
    for e in events:
        result.append(
            schemas.Event(
                id=e.id,
                game_name=e.game_name,
                from_time=e.from_time,
                to_time=e.to_time,
                participants=e.participants
            )
        )
    return result


@app.patch("/api/users/{user_id}/preferences", response_model=schemas.User)
def update_user_preferences(user_id: str, payload: dict = Body(...), db: Session = Depends(get_db)):
    """
    Expects body: { "preferences": [0,1,0,1,0] } (exactly 5 ints 0/1).
    """
    prefs = payload.get("preferences")
    if not isinstance(prefs, list) or len(prefs) != 5 or any((p not in (0, 1)) for p in prefs):
        raise HTTPException(status_code=400, detail="preferences must be a list of 5 integers (0 or 1)")

    user = db.query(models.User).filter(models.User.userID == user_id).first()
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    user.preferences = prefs
    db.add(user)
    db.commit()
    db.refresh(user)
    print(f"Updated preferences for {user_id} -> {prefs}")
    return user

@app.post("/api/events/{event_id}/leave", response_model=schemas.Event)
def leave_event(event_id: int, payload: LeaveEventRequest, db: Session = Depends(get_db)):
    print(f"[leave_event] request for event_id={event_id} payload={payload}")
    db_event = db.query(models.Event).filter(models.Event.id == event_id).first()
    if db_event is None:
        print(f"[leave_event] event {event_id} not found")
        raise HTTPException(status_code=404, detail="Event not found")

    try:
        participants_raw = db_event.participants or []
        participants: list[str] = []

        if isinstance(participants_raw, list):
            participants = [str(p) for p in participants_raw]
        elif isinstance(participants_raw, str):
            try:
                parsed = ast.literal_eval(participants_raw)
                if isinstance(parsed, list):
                    participants = [str(p) for p in parsed]
                else:
                    participants = [str(parsed)]
            except Exception:
                cleaned = participants_raw.strip("[] ")
                if cleaned:
                    participants = [p.strip(" '\"") for p in cleaned.split(",") if p.strip()]
                else:
                    participants = []
        else:
            participants = [str(participants_raw)]

        print(f"[leave_event] participants BEFORE: {participants}")

        user_to_remove = payload.user_id
        participants = [p for p in participants if p != user_to_remove and p.strip("'\"") != user_to_remove]
        seen = set()
        normalized = []
        for p in participants:
            if p not in seen:
                seen.add(p)
                normalized.append(p)

        db_event.participants = normalized

        db.add(db_event)
        db.commit()
        db.refresh(db_event)
        print(f"[leave_event] participants AFTER: {db_event.participants}")

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        print(f"[leave_event] unexpected error: {e}")
        raise HTTPException(status_code=500, detail=f"Error updating event participants: {e}")

    return schemas.Event(
        id=db_event.id,
        game_name=db_event.game_name,
        from_time=db_event.from_time,
        to_time=db_event.to_time,
        participants=db_event.participants or []
    )