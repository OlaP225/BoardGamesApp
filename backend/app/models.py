from sqlalchemy import Column, String
from sqlalchemy.orm import relationship
from .database import Base
from sqlalchemy import Integer, DateTime, ForeignKey

class User(Base):
    __tablename__ = "users"
    userID = Column(String, primary_key = True, index = True)
    username = Column(String, index = True)
    availabilities = relationship("Availability", back_populates="owner")
    events = relationship("Event", secondary="events_participants", back_populates="participants")

class Availability(Base):
    __tablename__ = "availability"
    id = Column(Integer, primary_key = True, index = True)
    from_time = Column(DateTime, index = True)
    to_time = Column(DateTime)

    owner_id = Column(String, ForeignKey("users.userID"))
    owner = relationship("User", back_populates="availabilities")

class Event(Base):
    __tablename__ = "events"
    id = Column(Integer, primary_key = True, index = True)
    game_name = Column(String, index = True)
    from_time = Column(DateTime, index = True)
    to_time = Column(DateTime)

    participants = relationship("User", secondary="events_participants", back_populates="events")

class EventParticipant(Base):
    __tablename__ = "events_participants"
    id = Column(Integer, primary_key = True, index = True)
    user_id = Column(String, ForeignKey("users.userID"))
    event_id = Column(Integer, ForeignKey("events.id"))







