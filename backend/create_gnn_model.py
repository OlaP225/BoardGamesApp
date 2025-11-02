import os
import numpy as np
import torch
import torch.nn.functional as F
from torch_geometric.data import Data, DataLoader
from torch_geometric.nn import GCNConv
from sklearn.model_selection import train_test_split
from app.config import DAYS_IN_SCHEDULE as DAYS, SLOTS_PER_DAY as SLOTS, PLAYERS_CONSTANT

MIN_PLAYERS_SLOT = 2
MAX_PLAYERS_SLOT = 4

CURRENT_DIR = os.path.dirname(__file__)
PROCESSED_DATA_DIR = os.path.abspath(os.path.join(CURRENT_DIR, '..', 'cplex_processed_data'))
MODEL_SAVE_PATH = os.path.join(CURRENT_DIR, 'app', 'gnn_model.pth')

def create_slot_graph_from_npz(file_path: str, pad_players: int = PLAYERS_CONSTANT):
    data = np.load(file_path)
    x_arr = data['x']  # (p, d, h)
    y_arr = data['y']  # (p, d, h)
    max_games = data.get('maxGames', None)

    if x_arr.ndim != 3 or y_arr.ndim != 3:
        raise ValueError(f"Unexpected shapes in {file_path}: x.ndim={x_arr.ndim} y.ndim={y_arr.ndim}")

    num_players = x_arr.shape[0]
    num_slots = DAYS * SLOTS

    X = x_arr.reshape(num_players, -1).T  # (num_slots, num_players)
    Y = y_arr.reshape(num_players, -1).T  # (num_slots, num_players)

    if X.shape[1] < pad_players:
        pad = pad_players - X.shape[1]
        X = np.pad(X, ((0, 0), (0, pad)), 'constant')
        Y = np.pad(Y, ((0, 0), (0, pad)), 'constant')
    elif X.shape[1] > pad_players:
        X = X[:, :pad_players]
        Y = Y[:, :pad_players]

    x_tensor = torch.tensor(X, dtype=torch.float)  # features: (num_slots, pad_players)
    y_tensor = torch.tensor(Y, dtype=torch.float)  # labels: (num_slots, pad_players)

    edges = []
    for s in range(num_slots - 1):
        if (s // SLOTS) == ((s + 1) // SLOTS):
            edges.append([s, s + 1])
            edges.append([s + 1, s])
    if len(edges) == 0:
        edge_index = torch.empty((2, 0), dtype=torch.long)
    else:
        edge_index = torch.tensor(edges, dtype=torch.long).t().contiguous()

    data_obj = Data(x=x_tensor, edge_index=edge_index, y=y_tensor)
    data_obj.num_players = num_players
    if max_games is not None:
        data_obj.max_games = np.array(max_games)
    return data_obj


class GNN(torch.nn.Module):
    def __init__(self, in_features, hidden=128, out_features=None):
        super().__init__()
        if out_features is None:
            out_features = in_features
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
            print("Skipping", f, "due to", e)
            continue
        positives = int(g.y.sum().item())
        if require_positive and positives == 0:
            continue
        graphs.append(g)
    print(f"Loaded {len(graphs)} graphs (from {len(files)} files).")
    return graphs

def train(model, train_loader, val_loader=None, epochs=200, lr=1e-3, pos_weight=None):
    optimizer = torch.optim.Adam(model.parameters(), lr=lr)
    if pos_weight is not None:
        criterion = torch.nn.BCEWithLogitsLoss(pos_weight=pos_weight)
    else:
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

    model = GNN(in_features=PLAYERS_CONSTANT, hidden=128, out_features=PLAYERS_CONSTANT)
    model = train(model, train_loader, val_loader=val_loader, epochs=200, lr=1e-3)

    torch.save(model.state_dict(), MODEL_SAVE_PATH)
    print("Model saved to:", MODEL_SAVE_PATH)


if __name__ == "__main__":
    main()