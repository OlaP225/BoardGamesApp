from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from . import models, schemas
from .schemas import ParticipantStatusUpdate
from .database import SessionLocal, engine
from .matchmaking import prepare_input_data, run_gnn_prediction
import numpy as np
import torch
from .config import *
import os
import sys
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from create_gnn_model import GNN, NUM_TAGS
from . import save_games
from fastapi import Body
import json

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
    prefs_json = json.dumps(user.prefs) if getattr(user, "prefs", None) else None
    db_user = models.User(userID = user.userID, username = user.username, prefs=prefs_json)
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

    in_features = PLAYERS_CONSTANT * (1 + NUM_TAGS)
    out_features = PLAYERS_CONSTANT
    model = GNN(in_features=in_features, hidden=128, out_features=out_features)
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
    events = (
        db.query(models.Event)
        .join(models.EventParticipant, models.Event.id == models.EventParticipant.event_id)
        .filter(models.EventParticipant.user_id == user_id)
        .all()
    )

    result = []
    for e in events:
        result.append(
            schemas.Event(
                id=e.id,
                game_name=e.game_name,
                from_time=e.from_time,
                to_time=e.to_time,
                status=e.status,
                participants=[p.userID for p in e.participants],
            )
        )
    return result




@app.post("/api/events/{event_id}/participants/status")
def update_participant_status(event_id: int, update: ParticipantStatusUpdate, db: Session = Depends(get_db)):
    participant = (
        db.query(models.EventParticipant)
        .filter(
            models.EventParticipant.event_id == event_id,
            models.EventParticipant.user_id == update.user_id
        )
        .first()
    )

    if not participant:
        raise HTTPException(status_code=404, detail="Participant not found for this event")

    if update.status not in ["accepted", "rejected"]:
        raise HTTPException(status_code=400, detail="Invalid status")

    participant.status = update.status
    db.commit()
    db.refresh(participant)

    accepted_count = (
        db.query(models.EventParticipant)
        .filter(
            models.EventParticipant.event_id == event_id,
            models.EventParticipant.status == "accepted"
        )
        .count()
    )
    if accepted_count >= 2:
        event = db.query(models.Event).filter(models.Event.id == event_id).first()
        if event.status != "accepted":
            event.status = "accepted"
            db.commit()

    return {"message": f"Status updated for user {update.user_id} on event {event_id} -> {update.status}"}

@app.get("/api/debug/events_participants")
def debug_links(db: Session = Depends(get_db)):
    links = db.query(models.EventParticipant).all()
    return [{"id": l.id, "user_id": l.user_id, "event_id": l.event_id, "status": l.status} for l in links]

