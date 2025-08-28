from sqlalchemy import Column, String
from .database import Base

class User(Base):
    __tablename__ = "users"
    userID = Column(String, primary_key = True, index = True)
    username = Column(String, index = True)


