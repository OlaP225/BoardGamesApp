from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from . import models, schemas
from .database import SessionLocal, engine

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