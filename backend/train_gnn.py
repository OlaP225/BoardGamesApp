from app.config import *
import os
import torch
from torch_geometric.loader import DataLoader
from sklearn.model_selection import train_test_split
import sys
from app.gnn_model import GNN, train_model
from app.gnn_utilis import create_bipartite_graph_from_data


if __name__ == "__main__":
    
    PROCESSED_DATA_DIR = os.path.join(os.path.dirname(__file__), '..', 'cplex_processed_data')
    
    print("Loading files from npz files and generating graphs...")
    all_files = [os.path.join(PROCESSED_DATA_DIR, f) for f in os.listdir(PROCESSED_DATA_DIR) if f.endswith('.npz')]
    graph_list = [create_bipartite_graph_from_data(f) for f in all_files]

    if not graph_list:
        print("Execution stopped: No graphs were created.")
        sys.exit(1)

    train_data, val_data = train_test_split(graph_list, test_size=0.2, random_state=42)
    print(f"Loaded {len(graph_list)} graphs. Training data: {len(train_data)}, Test data: {len(val_data)}.")

    train_loader = DataLoader(train_data, batch_size=8, shuffle=True)
    val_loader = DataLoader(val_data, batch_size=8)

    model = GNN(
        in_channels=1, 
        out_channels=1
    )

    train_model(model, train_loader, epochs=200)
    
    model_save_path = os.path.join(os.path.dirname(__file__), 'app', 'gnn_model.pth')
    torch.save(model.state_dict(), model_save_path)
    print(f"\nModel trained and saved in: {model_save_path}")


