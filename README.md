# BoardGamesApp

BoardGamesApp is a mobile application designed for board game enthusiasts to easily organize and join game sessions. It uses advanced optimization algorithms and Graph Neural Networks to intelligently match players based on their availability and game preferences.

## Table of Contents

* Project Overview
* Architecture
* Key Features
* Technologies
* Getting Started

# Project Overview

This project provides a comprehensive solution for coordinating board game meetups. It consists of an intuitive iOS mobile application, a FastAPI backend, and matchmaking algorithms. The core innovation lies in combining traditional optimization (CPLEX) for small-scale, precise matching with scalable Graph Neural Networks for efficient player grouping across larger communities, taking into account individual preferences and schedules.

<p align="center">
  <img src="https://github.com/user-attachments/assets/4100af6b-3788-4510-8f9c-a4f5f3c33d3f" 
       alt="BoardGamesApp Demo" 
       width="320" />
</p>


# Architecture

**iOS Mobile Application**
The frontend, developed with UIKit, provides an engaging user experience for managing profiles, availabilities, and viewing upcoming games. The app uses programmatic layouts (UIScrollView + UIStackView), custom cells (UINib), inline and wheel-style UIDatePickers, and clear empty states to guide users.

**Backend (FastAPI)**
A Python backend serves as the central API, managing user data, communicating with the database, and orchestrating matchmaking. Endpoints include user registration, availability CRUD, matchmaking trigger, and event retrieval.

**Database (PostgreSQL)**
Stores all persistent data: user profiles, game preferences, availability slots, and organized events. The backend uses SQLAlchemy for ORM.

**Matchmaking Algorithms**

* **CPLEX** Used offline to generate optimal game schedules for smaller groups. These optimal solutions are used as ground truth when training and validating the GNN.
* **Graph Neural Network (GNN):** A PyTorch Geometric model trained on CPLEX-processed data to generalize matchmaking to a larger user base. The GNN is integrated into the backend for inference and produces schedules that are translated into events the mobile client consumes.

# Key Features

**iOS Application**

* **User Interface:** Layout built with UIKit and Auto Layout.
* **Availability Management:** Users can add, edit, and delete availability slots using constrained date/time pickers.
* **Game Preference Selection:** Users select genres which influence matchmaking priorities.

**Backend & Matchmaking**

* **User & Availability Management APIs:** REST endpoints for user lifecycle and availability CRUD.
* **Matchmaking:** Using CPLEX and a trained GNN.
* **Event Notification System:** Notifies users about newly organized sessions.

# Technologies

**Frontend (iOS)**

* Swift 5+
* UIKit
* Auto Layout
* UserDefaults, URLSession, custom UITableView cells

**Backend & Algorithms**

* Python 3.9+
* FastAPI
* SQLAlchemy
* PyTorch & PyTorch Geometric]
* NumPy, scikit-learn
* IBM ILOG CPLEX
* Docker / Docker Compose

# Getting Started

Prerequisites: Docker, Xcode (recommended 14+), Python 3.10+ for backend tooling.

1. Clone the repository:
   `git clone [YOUR_REPO_LINK]`

2. Backend (Docker-compose):

   * Navigate to the project directory: `cd BoardGamesApp`
   * Launch backend & DB: `docker-compose up --build`
   * The backend will be available at `http://127.0.0.1:8000/` by default.

3. iOS client:

   * Open `BoardGamesApp.xcodeproj` in Xcode.
   * Update `APIService.baseURL` if needed (default `http://127.0.0.1:8000`).
   * Select a simulator or device and run the app.

4. Matchmaking & ML (optional):

   * Preprocess data to generate `.npz` training files (scripts included).
   * Train the GNN training script to produce `gnn_model.pth` or load a provided pretrained model.
   * CPLEX can be run to generate additional ground-truth schedules (offline).

