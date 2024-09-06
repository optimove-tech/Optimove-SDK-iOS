//  Copyright © 2022 Optimove. All rights reserved.

import Foundation

public struct PendingNotificationHelper {
    let storage: KeyValueStorage

    public init(storage: KeyValueStorage) {
        self.storage = storage
    }

    public func remove(id: Int) {
        var pendingNotifications = readAll()

        if let i = pendingNotifications.firstIndex(where: { $0.id == id }) {
            pendingNotifications.remove(at: i)

            save(pendingNotifications: pendingNotifications)
        }
    }

    public func remove(identifier: String) {
        var pendingNotifications = readAll()

        if let i = pendingNotifications.firstIndex(where: { $0.identifier == identifier }) {
            pendingNotifications.remove(at: i)

            save(pendingNotifications: pendingNotifications)
        }
    }

    public func readAll() -> [PendingNotification] {
        var pendingNotifications = [PendingNotification]()
        if let data: Data = storage[.pendingNotifications],
           let decoded = try? JSONDecoder().decode([PendingNotification].self, from: data)
        {
            pendingNotifications = decoded
        }

        return pendingNotifications
    }

    public func add(notification: PendingNotification) {
        var pendingNotifications = readAll()

        if let _ = pendingNotifications.firstIndex(where: { $0.id == notification.id }) {
            return
        }

        pendingNotifications.append(notification)

        save(pendingNotifications: pendingNotifications)
    }

    func save(pendingNotifications: [PendingNotification]) {
        if let data = try? JSONEncoder().encode(pendingNotifications) {
            storage.set(value: data, key: .pendingNotifications)
        }
    }
}
