//  Copyright © 2023 Optimove. All rights reserved.

import CoreData
import Foundation

final class KSEventModel: NSManagedObject {
    @discardableResult
    static func insert(
        into context: NSManagedObjectContext,
        uuid: UUID = UUID(),
        atTime: Date,
        eventType: String,
        userIdentifier: String,
        properties: [String: Any]? = nil
    ) throws -> KSEventModel {
        let eventCD: KSEventModel = try context.insertObject()
        eventCD.uuid = uuid.uuidString.lowercased()
        eventCD.happenedAt = NSNumber(value: Int64(atTime.timeIntervalSince1970 * 1000))
        eventCD.eventType = eventType
        eventCD.userIdentifier = userIdentifier
        if let properties = properties {
            eventCD.properties = try JSONSerialization.data(withJSONObject: properties)
        }
        return eventCD
    }
}

extension KSEventModel {
    @NSManaged var uuid: String
    @NSManaged var userIdentifier: String
    @NSManaged var happenedAt: NSNumber
    @NSManaged var eventType: String
    @NSManaged var properties: Data?
}

extension KSEventModel: Managed {
    static var entityName: String {
        return "Event"
    }

    static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \KSEventModel.happenedAt, ascending: true)]
    }
}

extension KSEventModel {}
