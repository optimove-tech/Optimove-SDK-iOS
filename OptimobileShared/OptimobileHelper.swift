//  Copyright © 2022 Optimove. All rights reserved.

import Foundation

let KS_MESSAGE_TYPE_PUSH = 1

enum OptimobileHelper {
    private static let installIdLock = DispatchSemaphore(value: 1)
    static let userIdLock = DispatchSemaphore(value: 1)

    static var installId: String {
        installIdLock.wait()
        defer {
            installIdLock.signal()
        }

        if let existingID = KeyValPersistenceHelper.object(forKey: OptimobileUserDefaultsKey.INSTALL_UUID.rawValue) {
            return existingID as! String
        }

        let newID = UUID().uuidString
        KeyValPersistenceHelper.set(newID, forKey: OptimobileUserDefaultsKey.INSTALL_UUID.rawValue)

        return newID
    }

    /**
      Returns the identifier for the user currently associated with the Kumulos installation record

      If no user is associated, it returns the Kumulos installation ID
     */
    static var currentUserIdentifier: String {
        userIdLock.wait()
        defer { userIdLock.signal() }
        if let userId = KeyValPersistenceHelper.object(forKey: OptimobileUserDefaultsKey.USER_ID.rawValue) as! String? {
            return userId
        }

        return OptimobileHelper.installId
    }

    static func getBadgeFromUserInfo(userInfo: [AnyHashable: Any]) -> NSNumber? {
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
        if let incrementBy = incrementBy, let currentVal = KeyValPersistenceHelper.object(forKey: OptimobileUserDefaultsKey.BADGE_COUNT.rawValue) as? NSNumber {
            newBadge = NSNumber(value: currentVal.intValue + incrementBy.intValue)

            if newBadge!.intValue < 0 {
                newBadge = 0
            }
        }

        return newBadge
    }
}
