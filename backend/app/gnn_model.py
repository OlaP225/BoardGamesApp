import torch
import torch.nn.functional as F
from torch_geometric.nn import GCNConv
from torch_geometric.data import Data
from torch_geometric.loader import DataLoader
import os
import json
from app.config import *
import numpy as np
from torch_geometric.nn.conv.gcn_conv import gcn_norm


class GNN(torch.nn.Module):
    def __init__(self, liczba_wejsc, liczba_wyjsc, ukryte=64):
        super(GNN, self).__init__()
        self.conv1 = GCNConv(liczba_wejsc, ukryte)
        self.conv2 = GCNConv(ukryte, liczba_wyjsc)

    def forward(self, data):
        x, edge_index = data.x, data.edge_index
        edge_index, _ = gcn_norm(edge_index, num_nodes=x.size(0), add_self_loops=True)
        x = F.relu(self.conv1(x, edge_index))
        x = F.dropout(x, p=0.5, training=self.training)
        x = self.conv2(x, edge_index)
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