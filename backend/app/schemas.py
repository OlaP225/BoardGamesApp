from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import List

class UserCreate(BaseModel):
    userID: str
    username: str
    preferences: list[int] = [0,0,0,0,0]

class User(UserCreate):
    model_config = ConfigDict(from_attributes=True)

class AvailabilityCreate(BaseModel):
    from_time: datetime
    to_time: datetime

class Availability(AvailabilityCreate):
    id: int
    owner_id: str

    model_config = ConfigDict(
        from_attributes=True,
        json_encoders={
            datetime: lambda v: v.isoformat(),
        }
    )

class EventBase(BaseModel):
    game_name: str
    from_time: datetime
    to_time: datetime

class EventCreate(EventBase):
    participants: List[str] = []

class Event(EventBase):
    id: int
    participants: list[str]
    model_config = ConfigDict(from_attributes=True)
