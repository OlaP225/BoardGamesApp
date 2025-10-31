import torch
import torch.nn.functional as F
from torch_geometric.nn import SAGEConv
from app.config import *
import numpy as np

class GNN(torch.nn.Module):
    def __init__(self, in_channels, out_channels, hidden_channels=128):
        super(GNN, self).__init__()
        self.conv1 = SAGEConv(in_channels, hidden_channels)
        self.conv2 = SAGEConv(hidden_channels, out_channels)
        self.edge_predictor = torch.nn.Sequential(
            torch.nn.Linear(out_channels * 2, hidden_channels),
            torch.nn.ReLU(),
            torch.nn.Linear(hidden_channels, 1)
        )

    def forward(self, x, edge_index):
        x = F.relu(self.conv1(x, edge_index))
        x = F.relu(self.conv2(x, edge_index))
        
        start_node_features = x[edge_index[0]]
        end_node_features = x[edge_index[1]]
    
        edge_features = torch.cat([start_node_features, end_node_features], dim=-1)
        return self.edge_predictor(edge_features)

def train_model(model, loader, epochs=200):
    optimizer = torch.optim.Adam(model.parameters(), lr=0.001)
    criterion = torch.nn.BCEWithLogitsLoss()
    model.train()

    print("Model training started...")
    for epoch in range(1, epochs + 1):
        total_loss = 0
        for data in loader:
            optimizer.zero_grad()
            out = model(data.x, data.edge_index)
            loss = criterion(out.squeeze(), data.y.squeeze())
            loss.backward()
            optimizer.step()
            total_loss += loss.item()
            
        avg_loss = total_loss / len(loader)
        if epoch % 10 == 0:
            print(f"`Epoch`: {epoch:03d}, Average loss: {avg_loss:.4f}")
    print("Training finished.")

def run_gnn_prediction(model, graph_data):
    model.eval()
    
    with torch.no_grad():
        logits = model(graph_data.x, graph_data.edge_index)
        probabilities = torch.sigmoid(logits)
        
        threshold = 0.1
        predictions = (probabilities > threshold).int().cpu().numpy()
        
        num_players = graph_data.num_players
        print(f"Number of players: {num_players}")
        final_schedule = np.zeros((num_players, NUMBER_OF_NODES), dtype=int)
        player_to_slot_edges = graph_data.edge_index[:, graph_data.edge_index[0] < num_players]
        
        for i in range(len(predictions)):
            if predictions[i] == 1:
                player_idx = player_to_slot_edges[0, i].item()
                slot_idx = player_to_slot_edges[1, i].item() - num_players
                final_schedule[player_idx, slot_idx] = 1
                
        return final_schedule.reshape(num_players, DAYS_IN_SCHEDULE, SLOTS_PER_DAY)