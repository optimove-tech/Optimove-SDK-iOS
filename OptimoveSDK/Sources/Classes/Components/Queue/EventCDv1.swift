//  Copyright © 2020 Optimove. All rights reserved.
//

import CoreData
import Foundation

@objc(EventCD)
/// The Event – Core Data managed object
final class EventCD: NSManagedObject {
    static func insert(
        into context: NSManagedObjectContext,
        event: OptistreamEvent,
        of type: OptistreamQueueType
    ) throws -> EventCD {
        let eventCD: EventCD = try context.insertObject()
        eventCD.uuid = event.metadata.eventId
        eventCD.data = try JSONEncoder().encode(event)
        eventCD.type = type.rawValue
        eventCD.date = event.timestamp
        return eventCD
    }
}

extension EventCD {
    @NSManaged private(set) var uuid: String
    @NSManaged private(set) var date: String
    @NSManaged private(set) var data: Data
    @NSManaged private(set) var type: String
}

extension EventCD: Managed {
    static var entityName: String {
        return "EventCD"
    }

    static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \EventCD.date, ascending: true)]
    }
}

extension EventCD {
    static func queueTypePredicate(queueType: OptistreamQueueType) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(EventCD.type), queueType.rawValue)
    }

    static func queueTypeAndUuidsPredicate(uuidStrings: [String], queueType: OptistreamQueueType) -> NSPredicate {
        return NSPredicate(
            format: "(%K IN %@) AND (%K == %@)",
            #keyPath(EventCD.uuid), uuidStrings,
            #keyPath(EventCD.type), queueType.rawValue
        )
    }
}
