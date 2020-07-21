//  Copyright © 2020 Optimove. All rights reserved.
//

import Foundation
import CoreData

@objc(EventCD)
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
        eventCD.creationDate = Date()
        return eventCD
    }
}

extension EventCD {

    @NSManaged fileprivate(set) var uuid: String
    @NSManaged fileprivate(set) var creationDate: Date
    @NSManaged fileprivate(set) var data: Data
    @NSManaged fileprivate(set) var type: String

}

extension EventCD: Managed {

    static var entityName: String {
        return "EventCD"
    }

    static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \EventCD.creationDate, ascending: true)]
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
