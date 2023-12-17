//  Copyright © 2023 Optimove. All rights reserved.

import CoreData

final class InAppMessageEntity: NSManagedObject {
    @NSManaged var id: Int64
    @NSManaged var updatedAt: Date
    @NSManaged var presentedWhen: String
    @NSManaged var content: ObjcJSON
    @NSManaged var data: ObjcJSON?
    @NSManaged var badgeConfig: ObjcJSON?
    @NSManaged var inboxConfig: ObjcJSON?
    @NSManaged var dismissedAt: Date?
    @NSManaged var inboxFrom: Date?
    @NSManaged var inboxTo: Date?
    @NSManaged var expiresAt: Date?
    @NSManaged var readAt: Date?
    @NSManaged var sentAt: Date?

    func isAvailable() -> Bool {
        if let availableFrom = inboxFrom, availableFrom.timeIntervalSinceNow > 0 {
            return false
        } else if let availableTo = inboxTo, availableTo.timeIntervalSinceNow < 0 {
            return false
        }
        return true
    }
}
