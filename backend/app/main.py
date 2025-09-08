from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from . import models, schemas
from .database import SessionLocal, engine
from .matchmaking import prepare_input_data
import json
from . import algorithm, gnn_model
import numpy as np
import torch
from .config import *
import os

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
    return {"message": "Serwer BoardGamesApp działa!"}

@app.post("/api/users", response_model=schemas.User)
def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user_existing = db.query(models.User).filter(models.User.userID == user.userID).first()
    if db_user_existing:
        raise HTTPException(status_code=400, detail="User with this ID already exists!")
    db_user = models.User(userID = user.userID, username = user.username)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)

    #test

    db_user_test = db.query(models.User).filter(models.User.userID == user.userID).first()
    if db_user_test:
        print("Sprawdzamy dostępności dla użytkownika", db_user_test.username)
        for slot in db_user_test.availabilities:
            print(f"  Dostępność: {slot.from_time} - {slot.to_time}")


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
    print(f"Zapisano dostępność dla użytkownika {user_id}: {db_availability.from_time} - {db_availability.to_time}")
    return db_availability

@app.delete("/api/availabilities/{availability_id}", status_code=204)
def delete_availability(availability_id: int, db: Session = Depends(get_db)):
    db_availability = db.query(models.Availability).filter(models.Availability.id == availability_id).first()
    if db_availability is None:
        raise HTTPException(status_code=404, detail="Availability not found")
    db.delete(db_availability)
    db.commit()
    print(f"Usunięto dostępność o ID {availability_id}")
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
        print(f"Krytyczny błąd: Nie znaleziono pliku modelu pod ściezką {model_path}")
        return
    
    print(f"Ładowanie modelu GNN...")
    global_gnn_model = gnn_model.GNN(liczba_wejsc=PLAYERS_CONSTANT, liczba_wyjsc=PLAYERS_CONSTANT)
    global_gnn_model.load_state_dict(torch.load(model_path, map_location=torch.device('cpu')))
    global_gnn_model.eval()
    print("Model GNN pomyślnie załadowany i gotowy do predykcji.")


@app.post("/api/matchmaking/run")
def run_matchmaking(db: Session = Depends(get_db)):
    print("\n\n --- Uruchamianie procesu matchmakingu... --- ")

    if global_gnn_model is None:
        raise HTTPException(status_code=503, detail="Model GNN nie jest załadowany lub wystąpił błąd.")
    
    input_data = prepare_input_data(db)
    if input_data is None:
        print("Zakończono: Brak danych do przetworzenia. ")
        return {"message": "Brak dostępności do przetworzenia"}

    print("Uruchamianie algorytmu GNN...")

    result_matrix = gnn_model.run_gnn_prediction(global_gnn_model, input_data)

    przetlumaczone_wydarzenia = algorithm.translate_schedule_to_events(
        schedule_per_player=result_matrix,
        user_ids=input_data["user_ids"]
    )
    
    algorithm.save_events_to_db(db, przetlumaczone_wydarzenia)

    print("--- Zakończono proces matchmakingu --- \n")
    return {"status": "success", "message": "Proces matchmakingu zakończony. Sprawdź logi serwera."}

