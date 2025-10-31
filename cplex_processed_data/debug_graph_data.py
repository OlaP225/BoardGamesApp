import os
import numpy as np
import torch
import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'backend')))

from app.gnn_utilis import create_bipartite_graph_from_data

DATA_DIR = os.path.dirname(__file__)

files = [os.path.join(DATA_DIR, f) for f in os.listdir(DATA_DIR) if f.endswith(".npz")]
print(f"Znaleziono {len(files)} plików .npz\n")

for path in files[:5]:  # pokażmy tylko kilka pierwszych
    print(f"📁 {os.path.basename(path)}")
    g = create_bipartite_graph_from_data(path)
    if g is None:
        continue

    y_np = g.y.cpu().numpy().flatten()
    pos = np.sum(y_np == 1)
    neg = np.sum(y_np == 0)

    print(f"  num_players = {g.num_players}")
    print(f"  num_slots   = {g.num_slots}")
    print(f"  edges total = {g.edge_index.shape[1]}")
    print(f"  positives   = {pos}, negatives = {neg}")
    print(f"  ratio       = {pos / (pos + neg + 1e-9):.4f}")
    print(f"  x shape     = {tuple(g.x.shape)}")
    print(f"  edge_index range: [{g.edge_index.min().item()}, {g.edge_index.max().item()}]")
    print("-" * 50)
