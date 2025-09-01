import os
import json
import numpy as np
import torch
import torch.nn.functional as F
from torch_geometric.nn import GCNConv
from torch_geometric.data import Data
from torch_geometric.loader import DataLoader

class GNN(torch.nn.Module):
    def __init__(self, liczba_wejsc, liczba_wyjsc, ukryte=64):
        super(GNN, self).__init__()
        self.conv1 = GCNConv(liczba_wejsc, ukryte)
        self.conv2 = GCNConv(ukryte, liczba_wyjsc)

    def forward(self, data):
        x, indeks_krawedzi = data.x, data.edge_index
        x = F.relu(self.conv1(x, indeks_krawedzi))
        x = F.dropout(x, p=0.5, training=self.training)
        x = self.conv2(x, indeks_krawedzi)
        return x
    
def run_gnn_prediction(model, ilosc_graczy, dostepnosc):
    model.eval()
    cechy_wezl = np.array(dostepnosc).reshape(ilosc_graczy, ilosc_wezlow).T
    padding_rozmiar = stala_graczy - ilosc_graczy
    cechy_wezl_padd = np.pad(cechy_wezl, ((0, 0), (0, padding_rozmiar)), 'constant')

    krawedzie = []
    for i in range(ilosc_wezlow - 1):
        dzien_wezla_i = i // godziny
        j = i + 1
        dzien_wezla_j = j // godziny
        if dzien_wezla_i == dzien_wezla_j:
            krawedzie.append([i, j])
            krawedzie.append([j, i])
    indeks_krawedzi = torch.tensor(krawedzie, dtype=torch.long).t().contiguous()

    graf_do_testu = Data(
        x=torch.tensor(cechy_wezl_padd, dtype=torch.float), 
        edge_index=indeks_krawedzi
    )

