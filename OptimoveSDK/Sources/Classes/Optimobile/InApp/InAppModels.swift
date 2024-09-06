//  Copyright © 2022 Optimove. All rights reserved.

import CoreData
import Foundation

enum InAppPresented: String {
    case IMMEDIATELY = "immediately"
    case NEXT_OPEN = "next-open"
    case NEVER = "never"
}

final class InAppMessageEntity: NSManagedObject {
    @NSManaged var id: Int64
    @NSManaged var updatedAt: NSDate
    @NSManaged var presentedWhen: String
    @NSManaged var content: NSDictionary
    @NSManaged var data: NSDictionary?
    @NSManaged var badgeConfig: NSDictionary?
    @NSManaged var inboxConfig: NSDictionary?
    @NSManaged var dismissedAt: NSDate?
    @NSManaged var inboxFrom: NSDate?
    @NSManaged var inboxTo: NSDate?
    @NSManaged var expiresAt: NSDate?
    @NSManaged var readAt: NSDate?
    @NSManaged var sentAt: NSDate?

    func isAvailable() -> Bool {
        let availableFrom = inboxFrom as Date?
        let availableTo = inboxTo as Date?

        if availableFrom != nil, availableFrom!.timeIntervalSinceNow > 0 {
            return false
        } else if availableTo != nil, availableTo!.timeIntervalSinceNow < 0 {
            return false
        }

        return true
    }
}

final class InAppMessage: NSObject {
    private(set) var id: Int64
    private(set) var updatedAt: NSDate
    private(set) var content: NSDictionary
    private(set) var data: NSDictionary?
    private(set) var badgeConfig: NSDictionary?
    private(set) var inboxConfig: NSDictionary?
    private(set) var dismissedAt: NSDate?
    private(set) var readAt: NSDate?
    private(set) var sentAt: NSDate?

    init(entity: InAppMessageEntity) {
        id = Int64(entity.id)
        updatedAt = entity.updatedAt.copy() as! NSDate
        content = entity.content.copy() as! NSDictionary
        data = entity.data?.copy() as? NSDictionary
        badgeConfig = entity.badgeConfig?.copy() as? NSDictionary
        inboxConfig = entity.inboxConfig?.copy() as? NSDictionary
        dismissedAt = entity.dismissedAt?.copy() as? NSDate
        readAt = entity.readAt?.copy() as? NSDate
        sentAt = entity.sentAt?.copy() as? NSDate
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? InAppMessage {
            return id == other.id
        }

        return super.isEqual(object)
    }

    override var hash: Int {
        id.hashValue
    }
}

public struct InAppButtonPress {
    public let deepLinkData: [AnyHashable: Any]
    public let messageId: Int64
    public let messageData: NSDictionary?
}
