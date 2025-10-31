from sqlalchemy.orm import Session
from datetime import datetime, timezone
from . import models
from app.config import *
import numpy as np
import torch
from torch_geometric.data import Data
from typing import Optional


start_of_day = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
days_in_schedule = 7 
slots_per_day = 10 

def prepare_input_data(db: Session) -> Optional[Data]:
    """
    Function takes data of all users and their availabilities from database and converts it to 
    Data object suitable for GNN model input.
    """
    all_users = db.query(models.User).filter(models.User.availabilities.any()).all()
    if not all_users:
        print("No users with availabilities found. Unable to prepare input data for matchmaking.")
        return None
    
    num_players = len(all_users)
    availability_matrix = [[[0] * slots_per_day for _ in range(days_in_schedule)] for _ in range(num_players)]
    max_games_per_user = [2] * num_players
    userid_index_map = {user.userID: i for i, user in enumerate(all_users)}
    print(f"start_of_day (UTC): {start_of_day}")
    for user in all_users:
        player_index = userid_index_map[user.userID]
        print(f"Processing user: {user.username} (ID: {user.userID}), index: {player_index}")
        if player_index is None:
            continue
        for availability in user.availabilities:
            from_time_utc = availability.from_time.replace(tzinfo=timezone.utc)
            to_time_utc = availability.to_time.replace(tzinfo=timezone.utc)

            print(f"  Availability from: {availability.from_time} (UTC: {from_time_utc})") # Dodaj to
            print(f"  Availability to: {availability.to_time} (UTC: {to_time_utc})") # Dodaj to

            delta_days = (from_time_utc.date() - start_of_day.date()).days
            day_index = delta_days

            if 0 <= day_index < days_in_schedule:
                start_hour = from_time_utc.hour
                end_hour = to_time_utc.hour

                print(f"  Start hour: {start_hour}, End hour: {end_hour}") # Dodaj to
                print(f"  MIN_HOUR: {MIN_HOUR}, slots_per_day: {slots_per_day}") # Dodaj to

                start_slot_index = start_hour - MIN_HOUR
                end_slot_index = end_hour - MIN_HOUR

                print(f"  Calculated start_slot_index: {start_slot_index}, end_slot_index: {end_slot_index}") # Dodaj to

                for slot_index in range(start_slot_index, end_slot_index):
                    if 0 <= slot_index < slots_per_day:
                        availability_matrix[player_index][day_index][slot_index] = 1
                        print(f"udalo sie")


    print("Successfully created availability matrix for all users.")
    print(availability_matrix)

    availability_flat = np.array(availability_matrix).reshape(num_players, -1) # here 2 dimen (num_players, days * slots)

    slot_features = torch.ones((NUMBER_OF_NODES, 1), dtype=torch.float)
    player_features = torch.tensor(max_games_per_user, dtype=torch.float).view(-1, 1)

    x = torch.cat([player_features, slot_features], dim=0)

    player_indices, slot_indices = np.where(availability_flat == 1)

    slot_indices_shifted = slot_indices + num_players

    edge_index_player_to_slot = torch.tensor([player_indices, slot_indices_shifted], dtype=torch.long)
    edge_index_slot_to_player = torch.tensor([slot_indices_shifted, player_indices], dtype=torch.long)
    edge_index = torch.cat([edge_index_player_to_slot, edge_index_slot_to_player], dim=1)

    graph_data = Data(x=x, edge_index=edge_index, num_players=num_players, num_slots=NUMBER_OF_NODES)
    graph_data.user_ids = [user.userID for user in all_users]

    print("Successfully prepared graph data for GNN model input.")


    if edge_index.numel() > 0:
        print("DEBUG: edge_index max:", int(edge_index.max().item()), "edge_index min:", int(edge_index.min().item()))
        assert int(edge_index.max().item()) < x.shape[0], "edge_index odnosi się do nieistniejących węzłów!"

    return graph_data