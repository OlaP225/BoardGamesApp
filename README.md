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

## ENG

# Installation & Deployment Guide

This document outlines the technical requirements and step-by-step instructions for deploying the app created as part of an Engineering Thesis.

## 1. System Requirements

Due to the native iOS client implementation, specific hardware and software environments are required.

### Hardware
*   **macOS Device:** A computer running macOS is **mandatory** to build and run the iOS client.

### Software
*   **Xcode:** Version 14.0 or newer (required for the iOS Client).
*   **Docker Desktop:** Required to containerize and run the Backend and Database services.
*   **Python 3.9.6+:** 


## 2. Installation Steps

### Step 1: Source Code Extraction
The source code is provided as a compressed archive (`.zip`) as part of the thesis submission.

1.  Locate the `praca_inynierska_aplikacja.zip` file.
2.  Extract the contents to a local directory on your machine.
3.  Open a terminal and navigate to the extracted folder:
    ```bash
    cd /path/to/extracted/praca_inynierska_aplikacja
    ```

### Step 2: Backend Deployment (Docker)
The backend logic and database are managed via Docker Compose to ensure environment consistency.

1.  From the project root directory, build and start the containers:
    ```bash
    docker-compose up --build
    ```
2.  Wait for the build process to finish. The backend service will be available by default at:
    *   **URL:** `http://127.0.0.1:8000/`

### Step 3: iOS Client Setup
1.  Launch **Xcode**.
2.  Open the project file `BoardGamesApp.xcodeproj` located in the source directory.
3.  **Network Configuration:**
    *   By default, the app connects to `http://127.0.0.1:8000`.
        ```
4.  **Execution:**
    *   Select a Simulator (e.g., iPhone 16) or a connected physical device from the scheme menu.
    *   Press **Run** (`Cmd + R`) to compile and launch the application.


## PL

# Instrukcja Uruchomienia

Niniejszy dokument zawiera specyfikację wymagań oraz instrukcję wdrożenia aplikacji do harmonogramowania gier planszowych. Projekt został zrealizowany w ramach pracy inżynierskiej.

## 1. Wymagania systemowe

Ze względu na implementację natywnego klienta mobilnego na system iOS, do uruchomienia pełnego środowiska wymagany jest specyficzny sprzęt i oprogramowanie.

### Sprzęt
*   **Komputer z systemem macOS:** Do kompilacji i uruchomienia klienta iOS wymagane jest urządzenie z systemem macOS.

### Oprogramowanie
*   **Xcode:** Wersja 14.0 lub nowsza
*   **Docker Desktop:** Wymagany do uruchomienia serwera backendowego oraz bazy danych w kontenerach.
*   **Python 3.9.6+:** 


## 2. Instrukcja instalacji

### Krok 1: Rozpakowanie kodu źródłowego
Kod źródłowy został dostarczony w formie archiwum `.zip` jako załącznik do pracy dyplomowej.

1.  Zlokalizuj plik `praca_inynierska_aplikacja.zip`.
2.  Rozpakuj archiwum w wybranym katalogu na dysku.
3.  Uruchom terminal i przejdź do katalogu projektu:
    ```bash
    cd /sciezka/do/katalogu/praca_inynierska_aplikacja
    ```

### Krok 2: Uruchomienie Backend'u (Docker)
Serwer aplikacji oraz baza danych są zarządzane przez Docker Compose, co zapewnia spójność środowiska uruchomieniowego.

1.  Będąc w głównym katalogu projektu, wykonaj polecenie:
    ```bash
    docker-compose up --build
    ```
2.  Proces budowania może potrwać kilka minut. Po jego zakończeniu backend będzie dostępny pod adresem:
    *   **URL:** `http://127.0.0.1:8000/`

### Krok 3: Klient iOS
1.  Uruchom środowisko **Xcode**.
2.  Wybierz opcję otwarcia projektu i wskaż plik `BoardGamesApp.xcodeproj` znajdujący się w rozpakowanym katalogu.
3.  **Konfiguracja połączenia:**
    *   Domyślnie aplikacja łączy się z adresem `http://127.0.0.1:8000` (localhost).
        ```
4.  **Uruchomienie:**
    *   Wybierz symulator (np. iPhone 16) z górnego menu.
    *   Naciśnij przycisk **Run** (`Cmd + R`), aby skompilować i uruchomić aplikację.


