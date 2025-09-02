import os
import json
import numpy as np
import torch
import torch.nn.functional as F
from torch_geometric.nn import GCNConv
from torch_geometric.data import Data
from torch_geometric.loader import DataLoader
from datetime import datetime, timedelta
import pytz
from . import schemas, models
from sqlalchemy.orm import Session

DAYS_IN_SCHEDULE = 30
SLOTS_PER_DAY = 28    # 30 minute slots from 8:00 - 22:00
NUMBER_OF_NODES = DAYS_IN_SCHEDULE * SLOTS_PER_DAY

PLAYERS_CONSTANT = 25 
MIN_PLAYERS = 2
MAX_PLAYERS = 3

class GNN(torch.nn.Module):
    def __init__(self, liczba_wejsc, liczba_wyjsc, ukryte=64):
        super(GNN, self).__init__()
        self.conv1 = GCNConv(liczba_wejsc, ukryte)
        self.conv2 = GCNConv(ukryte, liczba_wyjsc)

    def forward(self, data):
        x, indeks_krawedzi = data.x, data.edge_index
        x = F.relu(self.conv1(x, indeks_krawedzi))
        x = F.dropout(x, p=0.5, training=self.training)
        x = self.conv2(x, indeks_krawedzi)
        return x
    
def run_gnn_prediction(model, input_data):
    """
    Function runs GNN model predicition with prepared input data.
    """
    model.eval()

    number_of_players = input_data["iloscOsob"]
    availability = input_data["dostepnosc"]


    node_features = np.array(availability).reshape(number_of_players, NUMBER_OF_NODES).T
    padding_size = PLAYERS_CONSTANT - number_of_players
    if padding_size < 0:
        print("Error: Number of players exceeds the constant limit.")
        return None, None
    else:
        node_features_padding = np.pad(node_features, ((0, 0), (0, padding_size)), 'constant')

    edges = []
    for i in range(NUMBER_OF_NODES - 1):
        dzien_wezla_i = i // SLOTS_PER_DAY
        j = i + 1
        dzien_wezla_j = j // SLOTS_PER_DAY
        if dzien_wezla_i == dzien_wezla_j:
            edges.append([i, j])
            edges.append([j, i])
    indeks_krawedzi = torch.tensor(edges, dtype=torch.long).t().contiguous()

    graph_for_test = Data(
        x=torch.tensor(node_features_padding, dtype=torch.float), 
        edge_index=indeks_krawedzi
    )

    with torch.no_grad():
        logits = model(graph_for_test)
        probabilities = torch.sigmoid(logits)[:, :number_of_players]
    
    final_schedule_players = np.zeros((NUMBER_OF_NODES, number_of_players), dtype=int)
    for slot_idx in range(NUMBER_OF_NODES):
        slot_probabilities = probabilities[slot_idx].numpy()
        available_players_in_slot = node_features[slot_idx]
        sorted_player_indices = np.argsort(-slot_probabilities)
        
        selected_players = []
        for player_idx in sorted_player_indices:
            if available_players_in_slot[player_idx] == 1:
                selected_players.append(player_idx)
            if len(selected_players) == MAX_PLAYERS:
                break
        
        if len(selected_players) >= MIN_PLAYERS:
            for player_idx in selected_players:
                final_schedule_players[slot_idx, player_idx] = 1

    return final_schedule_players.T

def translate_schedule_to_events(schedule_per_player, user_ids, target_timezone_str="Europe/Warsaw"):
    target_timezone = pytz.timezone(target_timezone_str)
    open_games = {}
    events_indices = []

    schedule_by_slot = schedule_per_player.T
    for slot_index in range(len(schedule_by_slot)):
        current_players_indices = np.where(schedule_by_slot[slot_index] == 1)[0]
        if len(current_players_indices) < MIN_PLAYERS:
            current_players_indices = []

        if len(current_players_indices) == 0:
            if open_games:
                events_indices.extend(open_games.values())
                open_games = {} 
            continue

        current_group_key = tuple(sorted(current_players_indices))
        if current_group_key in open_games:
            open_games[current_group_key]['end_slot_index'] = slot_index + 1
        else:
            if open_games:
                events_indices.extend(open_games.values())
                
            open_games = {
                current_group_key: {
                    "start_slot_index": slot_index,
                    "end_slot_index": slot_index + 1,
                    "participant_indices": list(current_group_key)
                }
            }

    if open_games:
        events_indices.extend(open_games.values())

    final_events = []
    start_of_today = datetime.now(target_timezone).replace(hour=0, minute=0, second=0, microsecond=0)

    for event_data in events_indices:


        def slot_index_to_datetime(slot_index):
            day_offset = slot_index // SLOTS_PER_DAY
            slot_in_day = slot_index % SLOTS_PER_DAY
            
            hour_offset = slot_in_day // 2
            minute_offset = (slot_in_day % 2) * 30
            
            hour = 8 + hour_offset
            minute = minute_offset
            
            event_date = start_of_today + timedelta(days=day_offset)
            event_datetime = event_date.replace(hour=hour, minute=minute)
            
            return event_datetime

        participant_ids = [user_ids[i] for i in event_data["participant_indices"]]

        start_time = slot_index_to_datetime(event_data["start_slot_index"])
        end_time = slot_index_to_datetime(event_data["end_slot_index"])

        final_events.append(schemas.Event(
            id=0,
            game_name="Wylosowana Gra",
            from_time=start_time,
            to_time=end_time,
            status= "pending",
            participants= participant_ids
        ))

    print(f"Generated {len(final_events)} events from the schedule.")
    return final_events

def save_events_to_db(db: Session, events_to_create: list[schemas.Event]):
    db.query(models.Event).filter(models.Event.status == "pending").delete()

    for event_data in events_to_create:
        new_event = models.Event(
            game_name=event_data.game_name,
            from_time=event_data.from_time,
            to_time=event_data.to_time
        )
        participant_user_ids = event_data.participants
        participant_objects = db.query(models.User).filter(models.User.userID.in_(participant_user_ids)).all()
        new_event.participants = participant_objects

        db.add(new_event)
    
    try:
        db.commit()
        print(f"Pomyślnie zapisano {len(events_to_create)} nowych, proponowanych wydarzeń.")
    except Exception as e:
        print(f"BŁĄD podczas zapisu wydarzeń do bazy: {e}")
        db.rollback()

                            
    
    


