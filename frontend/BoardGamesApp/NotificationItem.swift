//
//  NotificationItem.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 03/11/2025.
//

import Foundation

enum NotificationType: String, Codable {
    case info
    case action
}

struct NotificationItem: Codable, Identifiable, Hashable {
    let id: String
    let date: Date
    let message: String
    let type: NotificationType
}
