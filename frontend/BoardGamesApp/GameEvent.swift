//
//  GameEvent.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 01/08/2025.
//

import Foundation

struct GameEvent {
    let id: Int
    let title: String
    let currentPlayersCount: Int
    let maxPlayersCount: Int
    let time: String
    let location: String
    let date: Date
    var participantsIDs: [String]
}
