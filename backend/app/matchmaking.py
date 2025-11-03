from datetime import datetime, timezone
from . import models
from app.config import *
import numpy as np
import torch
from torch_geometric.data import Data
from typing import Optional

days_in_schedule = 7 
slots_per_day = 10 

def prepare_input_data(db) -> Optional[Data]:
    all_users = db.query(models.User).filter(models.User.availabilities.any()).all()
    if not all_users:
        print("No users with availabilities found. Unable to prepare input data for matchmaking.")
        return None

    start_of_day = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)

    num_players = len(all_users)
    days = DAYS_IN_SCHEDULE
    slots = SLOTS_PER_DAY
    num_slots = days * slots

    avail_matrix = np.zeros((num_players, days, slots), dtype=np.int32)
    userid_index_map = {user.userID: i for i, user in enumerate(all_users)}

    for user in all_users:
        p_idx = userid_index_map[user.userID]
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
            day_index = delta_days
            if not (0 <= day_index < days):
                continue

            start_hour = from_utc.hour
            end_hour = to_utc.hour

            start_slot = start_hour - MIN_HOUR
            end_slot = end_hour - MIN_HOUR

            if start_slot < 0:
                start_slot = 0
            if end_slot > slots:
                end_slot = slots

            for s in range(start_slot, end_slot):
                if 0 <= s < slots:
                    avail_matrix[p_idx, day_index, s] = 1

    print("Successfully created availability matrix for all users.")
    print(avail_matrix.tolist())

    flat = avail_matrix.reshape(num_players, -1)
    node_feat = flat.T                              

    if node_feat.shape[1] < PLAYERS_CONSTANT:
        pad_cols = PLAYERS_CONSTANT - node_feat.shape[1]
        node_feat_padded = np.pad(node_feat, ((0, 0), (0, pad_cols)), 'constant')
    else:
        node_feat_padded = node_feat[:, :PLAYERS_CONSTANT]

    x_tensor = torch.tensor(node_feat_padded, dtype=torch.float)

    edges = []
    for s in range(num_slots - 1):
        if (s // slots) == ((s + 1) // slots):
            edges.append([s, s + 1])
            edges.append([s + 1, s])
    if edges:
        edge_index = torch.tensor(edges, dtype=torch.long).t().contiguous()
    else:
        edge_index = torch.empty((2, 0), dtype=torch.long)

    data = Data(x=x_tensor, edge_index=edge_index)
    data.user_ids = [u.userID for u in all_users]
    data.original_num_players = num_players
    data.avail_matrix = avail_matrix

    if edge_index.numel() > 0:
        max_idx = int(edge_index.max().item())
        assert max_idx < x_tensor.shape[0]

    print("Successfully prepared Data object for GNN inference.")
    return data

def run_gnn_prediction(model: torch.nn.Module, graph_data: Data, min_players: int = 2, max_players: int = 4):

    model.eval()
    with torch.no_grad():
        logits = model(graph_data)

    if isinstance(logits, torch.Tensor) and logits.ndim == 3 and logits.shape[0] == 1:
        logits = logits.squeeze(0)

    if not isinstance(logits, torch.Tensor):
        raise RuntimeError("Model did not return torch.Tensor logits")

    num_slots, feat_dim = logits.shape[0], logits.shape[1]
    orig_players = int(getattr(graph_data, "original_num_players", getattr(graph_data, "orig_num_players", PLAYERS_CONSTANT)))
    days = DAYS_IN_SCHEDULE
    slots = SLOTS_PER_DAY

    probs = torch.sigmoid(logits).cpu().numpy()

    avail_matrix = getattr(graph_data, "avail_matrix", None)
    if avail_matrix is None:
        raise RuntimeError("graph_data must contain avail_matrix (players, days, slots) for decoding")

    players = orig_players
    flat_avail = avail_matrix.reshape(players, -1).T

    try:
        print("DEBUG: logits min/max/mean:", float(logits.min().item()), float(logits.max().item()), float(logits.mean().item()))
    except Exception:
        pass
    print("DEBUG: sum probabilities (player->slot):", float(probs.sum()))

    final_flat = np.zeros_like(flat_avail, dtype=np.int32)

    for s in range(min(num_slots, flat_avail.shape[0])):
        slot_probs = probs[s, :players] 
        available_mask = flat_avail[s] == 1

        if not available_mask.any():
            continue
        sorted_idx = np.argsort(-slot_probs)

        selected = []
        for idx in sorted_idx:
            if not available_mask[idx]:
                continue
            selected.append(int(idx))
            if len(selected) >= max_players:
                break

        if len(selected) >= min_players:
            for p in selected:
                final_flat[s, p] = 1

    final_per_player = final_flat.T.reshape(players, days, slots).astype(int)

    print("GNN produced schedule (players x days x slots) with total assignments:", int(final_per_player.sum()))
    return final_per_player