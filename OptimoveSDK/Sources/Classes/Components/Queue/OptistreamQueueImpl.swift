//  Copyright © 2020 Optimove. All rights reserved.

import Foundation
import CoreData
import OptimoveCore
import UIKit

final class OptistreamQueueImpl {

    struct Constants {
        struct Store {
            static let name = "Events"
        }
    }

    private let container: PersistentContainer
    private let context: NSManagedObjectContext
    private let queueType: OptistreamQueueType
    private var dispatchTimer: Timer?

    var dispatchInterval: TimeInterval = 1 {
        didSet {
            startSaveTimer()
        }
    }

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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(save),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
        startSaveTimer()
    }

    private func startSaveTimer() {
        guard dispatchInterval > 0  else { return }
        if let dispatchTimer = dispatchTimer {
            dispatchTimer.invalidate()
            self.dispatchTimer = nil
        }
        context.perform { [weak self] in
            guard let self = self else { return }
            let currentRunLoop = RunLoop.current
            self.dispatchTimer = Timer(
                timeInterval: self.dispatchInterval,
                target: self,
                selector: #selector(self.save),
                userInfo: nil,
                repeats: false
            )
            currentRunLoop.add(self.dispatchTimer!, forMode: .common)
            currentRunLoop.run()
        }
    }

    @objc func save() {
        context.perform {
            self.context.saveOrRollback()
            self.startSaveTimer()
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
        context.perform {
            events.forEach { event in
                tryCatch {
                    _ = try EventCD.insert(into: self.context, event: event, of: self.queueType)
                }
            }
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
        let uuidStrings = events.map { $0.metadata.uuid }
        let predicate = EventCD.queueTypeAndUuidsPredicate(uuidStrings: uuidStrings, queueType: queueType)
        context.performChanges {
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: EventCD.entityName)
            fetch.predicate = predicate
            let request = NSBatchDeleteRequest(fetchRequest: fetch)
            _ = try? self.context.execute(request)
        }
    }
}
