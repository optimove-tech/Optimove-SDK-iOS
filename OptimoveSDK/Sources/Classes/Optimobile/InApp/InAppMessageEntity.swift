//  Copyright © 2023 Optimove. All rights reserved.

import CoreData
import GenericJSON
import OptimoveCore

final class InAppMessageEntity: NSManagedObject {
    static var dateFormatter: DateFormatter = {
        let dateParser = DateFormatter()
        dateParser.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        dateParser.locale = Locale(identifier: "en_US_POSIX")
        dateParser.timeZone = TimeZone(secondsFromGMT: 0)
        return dateParser
    }()

    static func insert(
        into context: NSManagedObjectContext,
        json: JSON
    ) throws -> InAppMessageEntity {
        var dismissedAt = try? dateFormatter.date(from: unwrap(json.openedAt?.stringValue)
        )
        let updatedAt: Date = try unwrap(
            dateFormatter.date(from: unwrap(json.updatedAt?.stringValue)
            )
        )
        let inbox: JSON = json.inbox ?? .null
        var inboxConfig: ObjcJSON? = ObjcJSON(json: inbox)
        var inboxFrom = try? dateFormatter.date(from:
            unwrap(inbox.from?.stringValue)
        )
        var inboxTo = try? dateFormatter.date(from:
            unwrap(inbox.to?.stringValue)
        )
        if let inboxDeletedAt = json.inboxDeletedAt?.stringValue {
            inboxConfig = nil
            inboxFrom = nil
            inboxTo = nil
            dismissedAt = dismissedAt ?? dateFormatter.date(from: inboxDeletedAt)
        }
        return try InAppMessageEntity.insert(
            into: context,
            id: Int64(unwrap(json.id?.doubleValue)),
            badgeConfig: ObjcJSON(json: json.badge ?? .null),
            content: ObjcJSON(json: json.content ?? .null),
            data: ObjcJSON(json: json.data ?? .null),
            dismissedAt: dismissedAt,
            expiresAt: try? dateFormatter.date(from:
                unwrap(inbox.expiresAt?.stringValue)
            ),
            inboxConfig: inboxConfig,
            inboxFrom: inboxFrom,
            inboxTo: inboxTo,
            presentedWhen: unwrap(json.presentedWhen?.stringValue),
            readAt: try? dateFormatter.date(from: unwrap(json.readAt?.stringValue)
            ),
            sentAt: try? dateFormatter.date(from: unwrap(json.sentAt?.stringValue)
            ),
            updatedAt: updatedAt
        )
    }

    static func insert(
        into context: NSManagedObjectContext,
        id: Int64,
        badgeConfig: ObjcJSON,
        content: ObjcJSON,
        data: ObjcJSON,
        dismissedAt: Date?,
        expiresAt _: Date?,
        inboxConfig: ObjcJSON?,
        inboxFrom: Date?,
        inboxTo: Date?,
        presentedWhen: String,
        readAt: Date?,
        sentAt: Date?,
        updatedAt: Date
    ) throws -> InAppMessageEntity {
        let entity: InAppMessageEntity = try context.insertObject()
        entity.id = id
        entity.badgeConfig = badgeConfig
        entity.content = content
        entity.data = data
        entity.dismissedAt = dismissedAt
        entity.inboxConfig = inboxConfig
        entity.inboxFrom = inboxFrom
        entity.inboxTo = inboxTo
        entity.presentedWhen = presentedWhen
        entity.readAt = readAt
        entity.sentAt = sentAt
        entity.updatedAt = updatedAt
        return entity
    }
}

extension InAppMessageEntity {
    @NSManaged var id: Int64
    @NSManaged var badgeConfig: ObjcJSON?
    @NSManaged var content: ObjcJSON
    @NSManaged var data: ObjcJSON?
    @NSManaged var dismissedAt: Date?
    @NSManaged var expiresAt: Date?
    @NSManaged var inboxConfig: ObjcJSON?
    @NSManaged var inboxFrom: Date?
    @NSManaged var inboxTo: Date?
    @NSManaged var presentedWhen: String
    @NSManaged var readAt: Date?
    @NSManaged var sentAt: Date?
    @NSManaged var updatedAt: Date

    func isAvailable() -> Bool {
        if let availableFrom = inboxFrom, availableFrom.timeIntervalSinceNow > 0 {
            return false
        } else if let availableTo = inboxTo, availableTo.timeIntervalSinceNow < 0 {
            return false
        }
        return true
    }
}

extension InAppMessageEntity: Managed {
    static var entityName: String {
        return "Message"
    }
}

extension InAppMessageEntity {
    static func queueTypePredicate(id: Int64) -> NSPredicate {
        return NSPredicate(format: "id = %i", #keyPath(InAppMessageEntity.id), id)
    }
}
