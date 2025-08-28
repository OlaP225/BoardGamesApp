from pydantic import BaseModel

class UserCreate(BaseModel):
    userID: str
    username: str

class User(UserCreate):
    class Config:
        from_atributes = True