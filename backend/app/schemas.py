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