import numpy as np
import torch 
from torch_geometric.data import Data
from app.config import *

def create_bipartite_graph_from_data(file_path: str):
    """
    Creates a bipartite graph based on dictionary.
    Edges are connecting players and time slots if the player is available in that slot.
    Nodes are both players and time slots. 
    """

    try:
        data = np.load(file_path)
        availability_matrix = data['x']
        max_games_per_player = data['maxGames']
        solution_matrix_y = data['y']
    except Exception as e:
        print(f"Error while loading a file {file_path}: {e}")
        return None

    num_players = availability_matrix.shape[0]
    
    availability_flat = availability_matrix.reshape(num_players, -1) #2 dim (num_players, days * slots)
    solution_flat_y = solution_matrix_y.reshape(num_players, -1)
    
    slot_features = torch.ones((NUMBER_OF_NODES, 1), dtype=torch.float)
    player_features = torch.tensor(max_games_per_player, dtype=torch.float).view(-1, 1)
    
    x = torch.cat([player_features, slot_features], dim=0)
    
    player_indices, slot_indices = np.where(availability_flat == 1)
    
    slot_indices_shifted = slot_indices + num_players
    
    edge_index_player_to_slot = torch.tensor([player_indices, slot_indices_shifted], dtype=torch.long)
    edge_index_slot_to_player = torch.tensor([slot_indices_shifted, player_indices], dtype=torch.long)
    edge_index = torch.cat([edge_index_player_to_slot, edge_index_slot_to_player], dim=1)
    
    solution_set = set(zip(*np.where(solution_flat_y == 1)))
    
    edge_labels = []
    for i in range(edge_index.shape[1]):
        player_idx = edge_index[0, i].item()
        slot_idx = edge_index[1, i].item() - num_players
        
        if (player_idx, slot_idx) in solution_set:
            edge_labels.append(1.0)
        else:
            edge_labels.append(0.0)

    y = torch.tensor(edge_labels, dtype=torch.float).view(-1, 1)   
    return Data(x=x, edge_index=edge_index, y=y, num_players=num_players, num_slots=NUMBER_OF_NODES)
