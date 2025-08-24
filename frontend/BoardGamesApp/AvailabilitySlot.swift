//
//  AvailabilitySlot.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 08/08/2025.
//

import Foundation

struct AvailabilitySlot: Equatable, Comparable {
    let date: Date
    let time: String
    
    static func < (lhs: AvailabilitySlot, rhs: AvailabilitySlot) -> Bool {
        return lhs.date < rhs.date
    }
}


