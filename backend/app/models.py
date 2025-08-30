from sqlalchemy import Column, String
from sqlalchemy.orm import relationship
from .database import Base
from sqlalchemy import Integer, DateTime, ForeignKey

class User(Base):
    __tablename__ = "users"
    userID = Column(String, primary_key = True, index = True)
    username = Column(String, index = True)
    availabilities = relationship("Availability", back_populates="owner")

class Availability(Base):
    __tablename__ = "availability"
    id = Column(Integer, primary_key = True, index = True)
    from_time = Column(DateTime, index = True)
    to_time = Column(DateTime)

    owner_id = Column(String, ForeignKey("users.userID"))
    owner = relationship("User", back_populates="availabilities")




