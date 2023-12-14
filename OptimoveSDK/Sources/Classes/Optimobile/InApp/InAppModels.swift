//  Copyright © 2022 Optimove. All rights reserved.

import CoreData
import Foundation
import GenericJSON

enum InAppPresented: String {
    case IMMEDIATELY = "immediately"
    case NEXT_OPEN = "next-open"
    case NEVER = "never"
}

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

final class InAppMessage {
    private(set) var id: Int64
    private(set) var updatedAt: Date
    private(set) var content: ObjcJSON
    private(set) var data: ObjcJSON?
    private(set) var badgeConfig: ObjcJSON?
    private(set) var inboxConfig: ObjcJSON?
    private(set) var dismissedAt: Date?
    private(set) var readAt: Date?
    private(set) var sentAt: Date?

    init(entity: InAppMessageEntity) {
        id = Int64(entity.id)
        updatedAt = entity.updatedAt
        content = entity.content
        data = entity.data
        badgeConfig = entity.badgeConfig
        inboxConfig = entity.inboxConfig
        dismissedAt = entity.dismissedAt
        readAt = entity.readAt
        sentAt = entity.sentAt
    }

    static func == (lhs: InAppMessage, rhs: InAppMessage) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Ensure that the InAppMessage conforms to Equatable and Hashable to provide the isEqual and hash functionality.
extension InAppMessage: Equatable, Hashable {}

public struct InAppButtonPress {
    public let deepLinkData: JSON
    public let messageId: Int64
    public let messageData: JSON?
}
