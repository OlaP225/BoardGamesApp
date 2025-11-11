import os
import numpy as np
import torch
import torch.nn.functional as F
from torch_geometric.data import Data, DataLoader
from torch_geometric.nn import GCNConv
from sklearn.model_selection import train_test_split
from app.config import DAYS_IN_SCHEDULE as DAYS, SLOTS_PER_DAY as SLOTS, PLAYERS_CONSTANT

NUM_TAGS = 5
MIN_PLAYERS_SLOT = 2
MAX_PLAYERS_SLOT = 4

CURRENT_DIR = os.path.dirname(__file__)
PROCESSED_DATA_DIR = os.path.abspath(os.path.join(CURRENT_DIR, '..', 'cplex_processed_data'))
MODEL_SAVE_PATH = os.path.join(CURRENT_DIR, 'app', 'gnn_model.pth')

def create_slot_graph_from_npz(file_path: str, pad_players: int = PLAYERS_CONSTANT):
    data = np.load(file_path)
    x_arr = data['x']  # (p, d, h) 3
    y_arr = data['y']  # (p, d, h) 3
    max_games = data.get('maxGames', None)

    if x_arr.ndim != 3 or y_arr.ndim != 3:
        raise ValueError(f"Unexpected shapes in {file_path}: x.ndim={x_arr.ndim} y.ndim={y_arr.ndim}")

    num_players = x_arr.shape[0]
    num_slots = DAYS * SLOTS

    avail_flat = x_arr.reshape(num_players, -1).T  # shape (num_slots, num_players)
    sched_flat = y_arr.reshape(num_players, -1).T  # shape (num_slots, num_players)

    prefs_arr = None
    if 'prefs' in data:
        prefs_arr = np.array(data['prefs'])
        # if 1D -> expand
        if prefs_arr.ndim == 1:
            prefs_arr = np.expand_dims(prefs_arr, axis=0)
        # if too few rows, pad; if too many, truncate
        if prefs_arr.shape[0] < num_players:
            pad_rows = num_players - prefs_arr.shape[0]
            pad_block = np.zeros((pad_rows, NUM_TAGS), dtype=int)
            prefs_arr = np.vstack([prefs_arr, pad_block])
        elif prefs_arr.shape[0] > num_players:
            prefs_arr = prefs_arr[:num_players]
        # ensure NUM_TAGS columns
        if prefs_arr.shape[1] < NUM_TAGS:
            pad_cols = NUM_TAGS - prefs_arr.shape[1]
            prefs_arr = np.hstack([prefs_arr, np.zeros((prefs_arr.shape[0], pad_cols), dtype=int)])
        elif prefs_arr.shape[1] > NUM_TAGS:
            prefs_arr = prefs_arr[:, :NUM_TAGS]
    else:
        # default: zeros
        prefs_arr = np.zeros((num_players, NUM_TAGS), dtype=int)

    # Now build X_expanded: for each slot s, for each player p (0..pad_players-1)
    # create vector [avail_bit, prefs_p( NUM_TAGS )] and flatten per slot
    in_per_player = 1 + NUM_TAGS
    in_features = pad_players * in_per_player
    X_expanded = np.zeros((num_slots, in_features), dtype=float)

    for s in range(num_slots):
        for p in range(pad_players):
            col_start = p * in_per_player
            col_end = col_start + in_per_player
            if p < num_players:
                avail_bit = float(avail_flat[s, p])
                prefs_p = prefs_arr[p].astype(float)
            else:
                avail_bit = 0.0
                prefs_p = np.zeros((NUM_TAGS,), dtype=float)
            X_expanded[s, col_start] = avail_bit
            X_expanded[s, col_start + 1:col_end] = prefs_p

    # Prepare Y: pad/truncate players dimension to pad_players
    if sched_flat.shape[1] <= pad_players:
        pad_cols = pad_players - sched_flat.shape[1]
        Y_padded = np.pad(sched_flat, ((0, 0), (0, pad_cols)), 'constant')
    else:
        Y_padded = sched_flat[:, :pad_players]

    x_tensor = torch.tensor(X_expanded, dtype=torch.float)  # (num_slots, in_features)
    y_tensor = torch.tensor(Y_padded, dtype=torch.float)   # (num_slots, pad_players)

    # build graph edges connecting consecutive slots in the same day
    edges = []
    for idx in range(num_slots - 1):
        if (idx // SLOTS) == ((idx + 1) // SLOTS):
            edges.append([idx, idx + 1])
            edges.append([idx + 1, idx])
    if len(edges) == 0:
        edge_index = torch.empty((2, 0), dtype=torch.long)
    else:
        edge_index = torch.tensor(edges, dtype=torch.long).t().contiguous()

    data_obj = Data(x=x_tensor, edge_index=edge_index, y=y_tensor)
    data_obj.num_players = num_players
    data_obj.in_per_player = in_per_player
    data_obj.pad_players = pad_players
    # attach prefs (trimmed/padded to num_players x NUM_TAGS) for later inspection / use
    data_obj.prefs = np.array(prefs_arr, dtype=int)

    if 'maxGames' in data:
        try:
            data_obj.max_games = np.array(data['maxGames'])
        except Exception:
            data_obj.max_games = None

    return data_obj



class GNN(torch.nn.Module):
    def __init__(self, in_features, out_features, hidden=128):
        super().__init__()
        self.conv1 = GCNConv(in_features, hidden)
        self.conv2 = GCNConv(hidden, out_features)

    def forward(self, data):
        x, edge_index = data.x, data.edge_index
        x = F.relu(self.conv1(x, edge_index))
        x = F.dropout(x, p=0.5, training=self.training)
        x = self.conv2(x, edge_index)
        return x


def load_all_graphs(processed_dir=PROCESSED_DATA_DIR, pad_players=PLAYERS_CONSTANT, require_positive=True):
    files = [os.path.join(processed_dir, f) for f in os.listdir(processed_dir) if f.endswith('.npz')]
    graphs = []
    for f in files:
        try:
            g = create_slot_graph_from_npz(f, pad_players=pad_players)
        except Exception as e:
            print("Skipped", f, "due to", e)
            continue
        positives = int(g.y.sum().item())
        if require_positive and positives == 0:
            continue
        graphs.append(g)
    print(f"Loaded {len(graphs)} graphs (from {len(files)} files).")
    return graphs

def train(model, train_loader, val_loader=None, epochs=200, lr=1e-3):
    optimizer = torch.optim.Adam(model.parameters(), lr=lr)
    criterion = torch.nn.BCEWithLogitsLoss()
    model.train()
    for epoch in range(1, epochs + 1):
        total_loss = 0.0
        for data in train_loader:
            optimizer.zero_grad()
            out = model(data)
            loss = criterion(out, data.y)
            loss.backward()
            optimizer.step()
            total_loss += loss.item()
        avg_loss = total_loss / len(train_loader)
        if epoch % 10 == 0 or epoch == 1:
            if val_loader is not None:
                prec, rec = evaluate(model, val_loader)
                print(f"Epoch {epoch:03d} loss={avg_loss:.4f} val_prec={prec:.4f} val_rec={rec:.4f}")
            else:
                print(f"Epoch {epoch:03d} loss={avg_loss:.4f}")
    return model

def evaluate(model, loader, threshold=0.5):
    model.eval()
    tp = 0; fp = 0; fn = 0
    with torch.no_grad():
        for data in loader:
            logits = model(data)
            probs = torch.sigmoid(logits)
            preds = (probs > threshold).int()
            y = data.y.int()
            tp += int(((preds == 1) & (y == 1)).sum().item())
            fp += int(((preds == 1) & (y == 0)).sum().item())
            fn += int(((preds == 0) & (y == 1)).sum().item())
    prec = tp / (tp + fp) if (tp + fp) > 0 else 0.0
    rec = tp / (tp + fn) if (tp + fn) > 0 else 0.0
    model.train()
    return prec, rec

def main():
    graphs = load_all_graphs()
    if len(graphs) == 0:
        print("No training graphs found")
        return

    train_graphs, val_graphs = train_test_split(graphs, test_size=0.2, random_state=42)
    train_loader = DataLoader(train_graphs, batch_size=8, shuffle=True)
    val_loader = DataLoader(val_graphs, batch_size=8)

    in_features = PLAYERS_CONSTANT * (1 + NUM_TAGS)
    out_features = PLAYERS_CONSTANT

    model = GNN(in_features=in_features, hidden=128, out_features=out_features)
    model = train(model, train_loader, val_loader=val_loader, epochs=200, lr=1e-3)

    torch.save(model.state_dict(), MODEL_SAVE_PATH)
    print("Model saved to:", MODEL_SAVE_PATH)


if __name__ == "__main__":
    main()