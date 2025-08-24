from fastapi import FastAPI
from pydantic import BaseModel

class User(BaseModel):
    userID: str
    username: str

app = FastAPI()

@app.post("/api/users")
def create_user(user: User):
    print(f"Otrzymano prośbę o stworzenie nowego użytkownika!")
    print("UserID: ", user.userID)
    print("Username: ", user.username )
    return {"status": "success", "message": f"Uzytkownik {user.username} został stworzony!"}

@app.get("/")
def read_root():
    return {"message": "Serwer BoardGamesApp działa!"}