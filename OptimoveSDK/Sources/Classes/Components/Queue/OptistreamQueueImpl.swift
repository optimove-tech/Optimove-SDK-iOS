//  Copyright © 2020 Optimove. All rights reserved.

import Foundation
import CoreData
import OptimoveCore

final class OptistreamQueueImpl {

    struct Constants {
        struct Store {
            static let name = "Events"
        }
    }

    private let container: PersistentContainer
    private let context: NSManagedObjectContext
    private let queueType: OptistreamQueueType

    init(
        queueType: OptistreamQueueType,
        container: PersistentContainer,
        tenant: Int
    ) throws {
        do {
            self.queueType = queueType
            self.container = container
            try container.loadPersistentStores(storeName: "\(Constants.Store.name)-\(tenant)")
            context = container.newBackgroundContext()
        } catch {
            Logger.error(error.localizedDescription)
            throw error
        }

    }

}

extension OptistreamQueueImpl: OptistreamQueue {

    var isEmpty: Bool {
        do {
            return try context.count(for: EventCD.sortedFetchRequest) == 0
        } catch {
            return true
        }
    }

    func enqueue(events: [OptistreamEvent]) {
        context.performAndWait {
            events.forEach { event in
                tryCatch {
                    _ = try EventCD.insert(into: self.context, event: event, of: self.queueType)
                }
            }
        }
        context.perform {
            self.context.saveOrRollback()
        }
    }

    func first(limit: Int) -> [OptistreamEvent] {
        do {
            return try context.performAndWait {
                let events = try EventCD.fetch(in: context) { request in
                    request.predicate = EventCD.queueTypePredicate(queueType: queueType)
                    request.sortDescriptors = EventCD.defaultSortDescriptors
                    request.fetchLimit = limit
                    request.returnsObjectsAsFaults = false
                }
                return events.compactMap { event in
                    do {
                        return try JSONDecoder().decode(OptistreamEvent.self, from: event.data)
                    } catch {
                        Logger.error(error.localizedDescription)
                        return nil
                    }
                }
            }
        } catch {
            Logger.error(error.localizedDescription)
            return []
        }
        
    }

    func remove(events: [OptistreamEvent]) {
        let uuidStrings = events.map { $0.metadata.uuid.uuidString }
        let predicate = EventCD.queueTypeAndUuidsPredicate(uuidStrings: uuidStrings, queueType: queueType)
        tryCatch {
            try context.performAndWait {
                let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: EventCD.entityName)
                fetch.predicate = predicate
                let request = NSBatchDeleteRequest(fetchRequest: fetch)
                try self.context.execute(request)
            }
        }
        context.perform {
            self.context.saveOrRollback()
        }
    }
}
