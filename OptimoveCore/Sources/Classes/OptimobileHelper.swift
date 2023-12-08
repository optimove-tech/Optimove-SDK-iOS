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

    // FIXME: Use PushNotifcation
    public func getBadgeFromUserInfo(userInfo: [AnyHashable: Any]) -> NSNumber? {
        let custom = userInfo["custom"] as? [AnyHashable: Any]
        let aps = userInfo["aps"] as? [AnyHashable: Any]

        if custom == nil || aps == nil {
            return nil
        }

        let incrementBy: NSNumber? = custom!["badge_inc"] as? NSNumber
        let badge: NSNumber? = aps!["badge"] as? NSNumber

        if badge == nil {
            return nil
        }

        var newBadge: NSNumber? = badge
        if let incrementBy = incrementBy, let currentVal: NSNumber = storage[.badgeCount] {
            newBadge = NSNumber(value: currentVal.intValue + incrementBy.intValue)

            if newBadge!.intValue < 0 {
                newBadge = 0
            }
        }

        return newBadge
    }
}
