//  Copyright © 2022 Optimove. All rights reserved.

import Foundation

enum PendingNotificationHelper {
    static func remove(id: Int) {
        var pendingNotifications = readAll()

        if let i = pendingNotifications.firstIndex(where: { $0.id == id }) {
            pendingNotifications.remove(at: i)

            save(pendingNotifications: pendingNotifications)
        }
    }

    static func remove(identifier: String) {
        var pendingNotifications = readAll()

        if let i = pendingNotifications.firstIndex(where: { $0.identifier == identifier }) {
            pendingNotifications.remove(at: i)

            save(pendingNotifications: pendingNotifications)
        }
    }

    static func readAll() -> [PendingNotification] {
        var pendingNotifications = [PendingNotification]()
        if let data = KeyValPersistenceHelper.object(forKey: OptimobileUserDefaultsKey.PENDING_NOTIFICATIONS.rawValue),
           let decoded = try? JSONDecoder().decode([PendingNotification].self, from: data as! Data)
        {
            pendingNotifications = decoded
        }

        return pendingNotifications
    }

    static func add(notification: PendingNotification) {
        var pendingNotifications = readAll()

        if let _ = pendingNotifications.firstIndex(where: { $0.id == notification.id }) {
            return
        }

        pendingNotifications.append(notification)

        save(pendingNotifications: pendingNotifications)
    }

    fileprivate static func save(pendingNotifications: [PendingNotification]) {
        if let data = try? JSONEncoder().encode(pendingNotifications) {
            KeyValPersistenceHelper.set(data, forKey: OptimobileUserDefaultsKey.PENDING_NOTIFICATIONS.rawValue)
        }
    }
}
