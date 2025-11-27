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

def run_gnn_prediction(model: torch.nn.Module, graph_data: Data, min_players: int = 2, max_players: int = 4):
    model.eval()
    with torch.no_grad():
        logits = model(graph_data)

    num_slots, feat_dim = logits.shape[0], logits.shape[1]
    players = int(graph_data.original_num_players)
    days = DAYS_IN_SCHEDULE
    slots = SLOTS_PER_DAY

    probs = torch.sigmoid(logits).cpu().numpy()
    avail_matrix = graph_data.avail_matrix
    flat_avail = avail_matrix.reshape(players, -1).T

    final_flat = np.zeros_like(flat_avail, dtype=np.int32)

    for s in range(min(num_slots, flat_avail.shape[0])):
        slot_probs = probs[s, :players]
        available_mask = flat_avail[s] == 1

        if not available_mask.any():
            continue

        sorted_idx = np.argsort(-slot_probs)
        print("Slot", s, "sorted player indices by prob:", sorted_idx.tolist(), flush=True)
        available_sorted = [i for i in sorted_idx if available_mask[i]]

        if len(available_sorted) < min_players:
            continue

        i = 0
        while i < len(available_sorted):
            group = available_sorted[i : i + max_players]
            if len(group) >= min_players:
                for p in group:
                    final_flat[s, p] = 1
            i += max_players

    final_per_player = final_flat.T.reshape(players, days, slots).astype(int)

    print("GNN produced schedule with total assignments:", int(final_per_player.sum()))
    return final_per_player