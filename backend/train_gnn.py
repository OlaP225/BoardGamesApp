from app.config import *
import os
import numpy as np
import torch
from torch_geometric.data import Data
from torch_geometric.loader import DataLoader
from sklearn.model_selection import train_test_split
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), 'app'))
from app.gnn_model import GNN

def load_processed_data(data_dir):
    """
    Loads data from directory, converts it to graph objects (pytorch geometric) and divides it into train and test sets.
    """

    all_files = [os.path.join(data_dir, f) for f in os.listdir(data_dir) if f.endswith('.npz')]
    graph_list = []

    edges = []
    for i in range(NUMBER_OF_NODES):
        j = i +1
        if (i + 1) % SLOTS_PER_DAY != 0:
            j = i + 1
            if j < NUMBER_OF_NODES:
                edges.append([i, j])
                edges.append([j, i])

    edge_index = torch.tensor(edges, dtype=torch.long).t().contiguous()

    for file_path in all_files:
        data = np.load(file_path)
        x = data['x']
        y = data['y']

        num_players = x.shape[0]
        x_reshaped = x.reshape(num_players, -1).T
        y_reshaped = y.reshape(num_players, -1).T

        num_nodes_in_data = x_reshaped.shape[0]
        if num_nodes_in_data != NUMBER_OF_NODES:
            print(f"OSTRZEŻENIE: Niezgodność wymiarów w pliku {file_path}. Oczekiwano {NUMBER_OF_NODES} węzłów, znaleziono {num_nodes_in_data}. Pomijam plik.")
            continue

        padding_size = PLAYERS_CONSTANT - num_players
        if padding_size > 0:
            x_padded = np.pad(x_reshaped, ((0, 0), (0, padding_size)), 'constant')
            y_padded = np.pad(y_reshaped, ((0, 0), (0, padding_size)), 'constant')
    
            graph = Data(
                x=torch.tensor(x_padded, dtype=torch.float),
                edge_index=edge_index.clone(),
                y=torch.tensor(y_padded, dtype=torch.float)
            )
            graph_list.append(graph)
    if not graph_list:
        return None, None
    
    train_data, test_data = train_test_split(graph_list, test_size = 0.2, random_state=42)
    print(f"Wczytano i przetworzono {len(graph_list)} próbek.")
    print(f"Zbiór treningowy: {len(train_data)} próbek.")
    print(f"Zbiór walidacyjny: {len(test_data)} próbek.")
    return train_data, test_data

def train_model(model, loader, epochs = 200):
    optimizer = torch.optim.Adam(model.parameters(), lr=0.01)
    criterion = torch.nn.BCEWithLogitsLoss()
    model.train()

    print("Rozpoczynam trening modelu...")
    for epoch in range(1, epochs + 1):
        total_loss = 0
        for data in loader:
            optimizer.zero_grad()
            out = model(data)
            loss = criterion(out, data.y)
            loss.backward()
            optimizer.step()
            total_loss += loss.item()
        avg_loss = total_loss / len(loader)
        if epoch % 10 == 0:
            print(f"Epoka: {epoch:03d}, Średnia strata: {avg_loss:.4f}")
    print("Trening zakończony.")

if __name__ == "__main__":
    PROCESSED_DATA_DIR = os.path.join(os.path.dirname(__file__), '..', 'processed_data')
    train_data, test_data = load_processed_data(PROCESSED_DATA_DIR)

    if train_data:
        train_loader = DataLoader(train_data, batch_size=16, shuffle=True)

        model = GNN(
            liczba_wejsc=PLAYERS_CONSTANT,
            liczba_wyjsc=PLAYERS_CONSTANT
        )

        train_model(model, train_loader, epochs=200)
        model_save_path = os.path.join(os.path.dirname(__file__), 'app', 'gnn_model.pth')
        torch.save(model.state_dict(), model_save_path)
        print(f"\nModel został wytrenowany i zapisany w: {model_save_path}")


