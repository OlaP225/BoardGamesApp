from pydantic import BaseModel, ConfigDict
from datetime import datetime

class UserCreate(BaseModel):
    userID: str
    username: str

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
    pass

class Event(EventBase):
    id: int
    participants: list[str] = []
    status: str
    model_config = ConfigDict(from_attributes=True)

class EventParticipantBase(BaseModel):
    user_id: str
    event_id: int
    status: str = "pending"


class EventParticipantCreate(EventParticipantBase):
    pass


class EventParticipant(EventParticipantBase):
    id: int
    model_config = ConfigDict(from_attributes=True)
