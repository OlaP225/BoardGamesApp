//
//  NotificationStore.swift
//  BoardGamesApp
//
//  Created by Aleksandra Plichta on 16/11/2025.
//

import Foundation

final class NotificationStore {
    static let shared = NotificationStore()
    private let key = "app_notifications_v1"
    private let queue = DispatchQueue(label: "NotificationStore.queue", attributes: .concurrent)

    private init() {}

    func loadAll() -> [NotificationItem] {
        queue.sync {
            guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode([NotificationItem].self, from: data)
            } catch {
                print("NotificationStore: load error", error)
                return []
            }
        }
    }

    func saveAll(_ items: [NotificationItem]) {
        queue.async(flags: .barrier) {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(items)
                UserDefaults.standard.set(data, forKey: self.key)
            } catch {
                print("NotificationStore: save error", error)
            }
        }
    }

    func add(_ item: NotificationItem) {
        var current = loadAll()
        current.insert(item, at: 0)
        saveAll(current)
        print("[NotificationStore] saved item id=\(item.id) total=\(current.count)")
    }
}
