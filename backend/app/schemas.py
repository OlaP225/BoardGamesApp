from pydantic import BaseModel
from datetime import datetime

class UserCreate(BaseModel):
    userID: str
    username: str

class User(UserCreate):
    class Config:
        from_atributes = True

class AvailabilityCreate(BaseModel):
    from_time: datetime
    to_time: datetime

class Availability(AvailabilityCreate):
    id: int
    owner_id: str

    class Config:
        from_attributes = True