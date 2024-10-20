//  Copyright © 2022 Optimove. All rights reserved.

import Foundation

public struct OptimobileHelper {
    static let installIdLock = DispatchSemaphore(value: 1)
    public static let userIdLock = DispatchSemaphore(value: 1)

    let storage: KeyValueStorage

    public init(storage: KeyValueStorage) {
        self.storage = storage
    }

    public func installId() -> String {
        OptimobileHelper.installIdLock.wait()
        defer {
            OptimobileHelper.installIdLock.signal()
        }

        if let existingID: String = storage[.installUUID] {
            return existingID
        }

        let newID = UUID().uuidString
        storage.set(value: newID, key: .installUUID)
        return newID
    }

    /**
      Returns the identifier for the user currently associated with the Kumulos installation record

      If no user is associated, it returns the Kumulos installation ID
     */
    public func currentUserIdentifier() -> String {
        OptimobileHelper.userIdLock.wait()
        defer { OptimobileHelper.userIdLock.signal() }
        if let userId: String = storage[.userID] {
            return userId
        }

        return installId()
    }

    public func getBadge(notification: PushNotification) -> Int? {
        if let incrementBy = notification.badgeIncrement,
           let current: Int = storage[.badgeCount]
        {
            let badge = current + incrementBy
            return badge < 0 ? 0 : badge
        }

        return notification.aps.badge
    }
}
