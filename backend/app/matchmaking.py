from datetime import datetime, timezone
from . import models
from app.config import *
import numpy as np
import torch
from torch_geometric.data import Data
from typing import Optional

days_in_schedule = 7 
slots_per_day = 10 

def prepare_input_data(db, requesting_user_id: str) -> Optional[Data]:
    
    requesting_user = (
        db.query(models.User)
        .filter(models.User.userID == requesting_user_id)
        .first()
    )
    user_prefs = np.array(requesting_user.preferences, dtype=np.int32)
    compatible_users = []
    
    all_users = db.query(models.User).filter(models.User.availabilities.any()).all()
    for u in all_users:
        if u.preferences is None:
            continue

        prefs = np.array(u.preferences, dtype=np.int32)

        if np.dot(user_prefs, prefs) > 0:
            compatible_users.append(u)

    if not compatible_users:
        print("No compatible users with availabilities.")
        return None

    print(f"Matched compatible users count: {len(compatible_users)}")

    start_of_day = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)

    num_players = len(compatible_users)
    days = DAYS_IN_SCHEDULE
    slots = SLOTS_PER_DAY
    num_slots = days * slots

    num_preferences = 5
    preferences_matrix = np.zeros((num_players, num_preferences), dtype=np.int32)

    for i, user in enumerate(compatible_users):
        if user.preferences:
            preferences_matrix[i] = np.array(user.preferences)

    avail_matrix = np.zeros((num_players, days, slots), dtype=np.int32)
    user_id_index_map = {u.userID: i for i, u in enumerate(compatible_users)}

    for user in compatible_users:
        p_idx = user_id_index_map[user.userID]

        for availability in user.availabilities:
            from_utc = availability.from_time
            to_utc = availability.to_time

            if from_utc.tzinfo is None:
                from_utc = from_utc.replace(tzinfo=timezone.utc)
            else:
                from_utc = from_utc.astimezone(timezone.utc)

            if to_utc.tzinfo is None:
                to_utc = to_utc.replace(tzinfo=timezone.utc)
            else:
                to_utc = to_utc.astimezone(timezone.utc)

            delta_days = (from_utc.date() - start_of_day.date()).days
            if not (0 <= delta_days < days):
                continue

            start_slot = from_utc.hour - MIN_HOUR
            end_slot = to_utc.hour - MIN_HOUR
            start_slot = max(0, start_slot)
            end_slot = min(slots, end_slot)

            for s in range(start_slot, end_slot):
                avail_matrix[p_idx, delta_days, s] = 1

    flat = avail_matrix.reshape(num_players, -1)
    node_feat = flat.T


    if node_feat.shape[1] < PLAYERS_CONSTANT:
        pad_cols = PLAYERS_CONSTANT - node_feat.shape[1]
        node_feat = np.pad(node_feat, ((0, 0), (0, pad_cols)), 'constant')

    else:
        node_feat = node_feat[:, :PLAYERS_CONSTANT]

    x_tensor = torch.tensor(node_feat, dtype=torch.float)

    edges = []
    for s in range(num_slots - 1):
        if (s // slots) == ((s + 1) // slots):
            edges.append([s, s + 1])
            edges.append([s + 1, s])

    edge_index = (
        torch.tensor(edges, dtype=torch.long).t().contiguous()
        if edges else
        torch.empty((2, 0), dtype=torch.long)
    )

    data = Data(x=x_tensor, edge_index=edge_index)
    data.user_ids = [u.userID for u in compatible_users]
    data.original_num_players = num_players
    data.avail_matrix = avail_matrix
    data.preferences_matrix = preferences_matrix

    print("Prepared GNN Data (with preference filtering).")
    return data

def run_gnn_prediction(model: torch.nn.Module, graph_data: Data, prob_threshold: float = 0.1):
    model.eval()
    with torch.no_grad():
        logits = model(graph_data)

    num_slots, feat_dim = logits.shape[0], logits.shape[1]
    players = int(graph_data.original_num_players)
    days = DAYS_IN_SCHEDULE
    slots = SLOTS_PER_DAY

    probs = torch.sigmoid(logits).cpu().numpy()

    final_flat = np.zeros((num_slots, players), dtype=np.int32)
    avail_matrix = graph_data.avail_matrix

    for s in range(num_slots):
        slot_probs = probs[s, :players]
        day_idx = s // slots
        slot_idx = s % slots

        print(f"Slot {s} player probabilities: {slot_probs.tolist()}")

        for i, p in enumerate(slot_probs):
            if p > prob_threshold and avail_matrix[i, day_idx, slot_idx] == 1:
                final_flat[s, i] = 1

        selected_idx = [i for i, val in enumerate(final_flat[s]) if val == 1]
        if selected_idx.count:
            print(f"Slot {s} selected players (prob > {prob_threshold} & available): {selected_idx}")

    final_per_player = np.zeros((players, days, slots), dtype=int)
    for player_idx in range(players):
        for s in range(num_slots):
            day_idx = s // slots
            slot_idx = s % slots
            final_per_player[player_idx, day_idx, slot_idx] = final_flat[s, player_idx]

    print("GNN produced schedule with total assignments:", int(final_per_player.sum()))
    return final_per_player


