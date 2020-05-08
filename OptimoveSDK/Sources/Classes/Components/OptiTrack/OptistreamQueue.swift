//  Copyright © 2020 Optimove. All rights reserved.

import Foundation
import OptimoveCore

protocol OptistreamQueue {
    var eventCount: Int { get }
    func enqueue(events: [OptistreamEvent])
    func first(limit: Int) -> [OptistreamEvent]
    func remove(events: [OptistreamEvent])
}

struct QueueFilenameConstants {
    static let track = "track_queue.json"
    static let realtime = "realtime_queue.json"
}

final class OptistreamQueueImpl {

    private let storage: OptimoveStorage
    private var inMemoryEvents = [OptistreamEvent]()
    private let queuePersistanceFileName: String

    init(
        storage: OptimoveStorage,
        queuePersistanceFileName: String
    ) {
        self.storage = storage
        self.queuePersistanceFileName = queuePersistanceFileName
        inMemoryEvents = loadEventFromStorageToMemory()
    }

    private func loadEventFromStorageToMemory() -> [OptistreamEvent] {
        guard storage.isExist(fileName: queuePersistanceFileName, shared: false) else { return [] }
        do {
            return try storage.load(fileName: queuePersistanceFileName, shared: false)
        } catch {
            Logger.error(error.localizedDescription)
            return []
        }
    }

    private func save(events: [OptistreamEvent]) {
        do {
            try storage.save(
                data: events,
                toFileName: queuePersistanceFileName,
                shared: false
            )
        } catch {
            Logger.error("Queue: Events file could not be saved. Reason: \(error.localizedDescription)")
        }
    }

}

extension OptistreamQueueImpl: OptistreamQueue {

    var eventCount: Int {
        return inMemoryEvents.count
    }

    func enqueue(events: [OptistreamEvent]) {
        Logger.debug("Queue: Enqueue \(events.count) events:\n\(events.map({ $0.event }))")
        inMemoryEvents.append(contentsOf: events)
        // TODO: dispatch on will resign active
        save(events: inMemoryEvents)
    }

    func first(limit: Int) -> [OptistreamEvent] {
        let amount = limit <= eventCount ? limit : eventCount
        return Array(inMemoryEvents[0..<amount])
    }

    func remove(events: [OptistreamEvent]) {
        Logger.debug("Queue: Dequeue \(events.count) events:\n\(events.map({ $0.event }))")
        inMemoryEvents = inMemoryEvents.filter { cachedEvent in
            !events.contains(cachedEvent) // O(n*n)
        }
        save(events: inMemoryEvents)
    }
}
