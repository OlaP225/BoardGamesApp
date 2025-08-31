//
//  AvailabilitySlot.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 08/08/2025.
//

import Foundation

struct AvailabilitySlot: Equatable, Comparable {
    let id: Int
    let from: Date
    let to: Date
    
    static func == (lhs: AvailabilitySlot, rhs: AvailabilitySlot) -> Bool {
        return abs(lhs.from.timeIntervalSince(rhs.from)) < 1 && abs(lhs.to.timeIntervalSince(rhs.to)) < 1
    }
    
    static func < (lhs: AvailabilitySlot, rhs: AvailabilitySlot) -> Bool {
        return lhs.from < rhs.from
    }
}


