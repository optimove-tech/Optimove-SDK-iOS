//  Copyright © 2020 Optimove. All rights reserved.

import CoreData
import Foundation
import OptimoveCore
import UIKit

final class OptistreamQueueImpl {
    enum Constants {
        enum Store {
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
            try container.loadPersistentStores(
                storeName: "\(Constants.Store.name)-\(tenant)"
            )
            context = container.newBackgroundContext()
            context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)
        } catch {
            Logger.error(error.localizedDescription)
            throw error
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(save),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }

    @objc func save() {
        context.safeSaveOrRollback()
    }
}

extension OptistreamQueueImpl: OptistreamQueue {
    var isEmpty: Bool {
        do {
            return try context.safeTryPerformAndWait { isSafe in
                if !isSafe {
                    Logger.error("Unable to get events count. Persistent store unavailable")
                    return true
                }
                return try context.count(for: EventCDv2.sortedFetchRequest) == 0
            }
        } catch {
            return true
        }
    }

    func enqueue(events: [OptistreamEvent]) {
        context.safePerformAndWait { isSafe in
            if !isSafe {
                Logger.error("Unable to enqueue events. Persistent store unavailable")
                return
            }
            events.forEach { event in
                tryCatch {
                    _ = try EventCDv2.insert(into: self.context, event: event, of: self.queueType)
                }
            }
        }
    }

    func first(limit: Int) -> [OptistreamEvent] {
        do {
            return try context.safeTryPerformAndWait { isSafe in
                if !isSafe {
                    Logger.error("Unable to fetch events. Persistent store unavailable")
                    return []
                }
                let events = try EventCDv2.fetch(in: context) { request in
                    request.predicate = EventCDv2.queueTypePredicate(queueType: queueType)
                    request.sortDescriptors = EventCDv2.defaultSortDescriptors
                    request.fetchLimit = limit
                    request.returnsObjectsAsFaults = false
                }
                return events.compactMap { event in
                    do {
                        let optistreamEvent = try JSONDecoder().decode(OptistreamEvent.self, from:
                            event.data)
                        return optistreamEvent
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
        let eventIds = events.map(\.metadata.eventId)
        let predicate = EventCDv2.queueTypeAndEventIdsPredicate(eventIds: eventIds, queueType: queueType)
        context.safePerformAndWait { isSafe in
            if !isSafe {
                Logger.error("Unable to remove events. Persistent store unavailable")
                return
            }
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: EventCDv2.entityName)
            fetch.predicate = predicate
            tryCatch {
                let results: [NSManagedObject] = try cast(context.fetch(fetch))
                results.forEach { object in
                    context.delete(object)
                }
            }
        }
    }
}
