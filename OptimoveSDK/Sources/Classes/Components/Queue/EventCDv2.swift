//  Copyright © 2020 Optimove. All rights reserved.
//

import Foundation
import CoreData

@objc(EventCDv2)
/// The Event – Core Data managed object
final class EventCDv2: NSManagedObject {

    static func insert(
        into context: NSManagedObjectContext,
        event: OptistreamEvent,
        of type: OptistreamQueueType
    ) throws -> EventCDv2 {
        let eventCD: EventCDv2 = try context.insertObject()
        eventCD.eventId = event.metadata.eventId
        eventCD.data = try JSONEncoder().encode(event)
        eventCD.type = type.rawValue
        eventCD.creationDate = Date()
        return eventCD
    }
}

extension EventCDv2 {

    @NSManaged fileprivate(set) var eventId: String
    @NSManaged fileprivate(set) var creationDate: Date
    @NSManaged fileprivate(set) var data: Data
    @NSManaged fileprivate(set) var type: String

}

extension EventCDv2: Managed {

    static var entityName: String {
        return "EventCD2"
    }

    static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \EventCDv2.creationDate, ascending: true)]
    }

}

extension EventCDv2 {

    static func queueTypePredicate(queueType: OptistreamQueueType) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(EventCDv2.type), queueType.rawValue)
    }

    static func queueTypeAndEventIdsPredicate(eventIds: [String], queueType: OptistreamQueueType) -> NSPredicate {
        return NSPredicate(
            format: "(%K IN %@) AND (%K == %@)",
            #keyPath(EventCDv2.eventId), eventIds,
            #keyPath(EventCDv2.type), queueType.rawValue
        )
    }
}
