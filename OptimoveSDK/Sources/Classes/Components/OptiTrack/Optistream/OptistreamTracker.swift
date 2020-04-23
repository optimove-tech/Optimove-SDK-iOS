//  Copyright © 2020 Optimove. All rights reserved.

import Foundation
import OptimoveCore

typealias OptistreamEvent = OptimoveCore.OptistreamEvent
typealias OptistreamEventBuilder = OptimoveCore.OptistreamEventBuilder
typealias OptistreamNetworking = OptimoveCore.OptistreamNetworking

final class OptistreamTracker {

    private let queue: OptistreamQueue
    private let optirstreamEventBuilder: OptistreamEventBuilder
    private let networking: OptistreamNetworking

    init(queue: OptistreamQueue,
         optirstreamEventBuilder: OptistreamEventBuilder,
         networking: OptistreamNetworking) {
        self.queue = queue
        self.optirstreamEventBuilder = optirstreamEventBuilder
        self.networking = networking
    }

}

extension OptistreamTracker: Tracker {

    func track(event: Event) {
        tryCatch {
            let event = try optirstreamEventBuilder.build(event: event)
//            queue.enqueue(events: [event])
            networking.send(event: event) { (result) in
                switch result {
                case .success(let response):
                    print(response)
                case .failure(let error):
                    print(error)
                }
            }
        }
    }

    func dispatch() {

    }

}

import OptimoveCore

protocol OptistreamQueue {
    var eventCount: Int { get }
    func enqueue(events: [OptistreamEvent])
    func first(limit: Int) -> [OptistreamEvent]
    func remove(events: [OptistreamEvent])
}

final class OptistreamQueueImpl {

    private struct Constants {
        static let queuePersistanceFileName = "optistream_queue"
    }

    private let storage: OptimoveStorage
    private var inMemoryEvents = [OptistreamEvent]()

    init(storage: OptimoveStorage) {
        self.storage = storage
        inMemoryEvents = loadEventFromStorageToMemory()
    }

    private func loadEventFromStorageToMemory() -> [OptistreamEvent] {
        guard storage.isExist(fileName: Constants.queuePersistanceFileName, shared: false) else { return [] }
        do {
            let data = try storage.load(fileName: Constants.queuePersistanceFileName, shared: false)
            return try JSONSerialization.jsonObject(with: data, options: []) as? [OptistreamEvent] ?? []
        } catch {
            Logger.error(error.localizedDescription)
            return []
        }
    }

    private func save(events: [OptistreamEvent]) {
        do {
            try storage.save(
                data: events,
                toFileName: Constants.queuePersistanceFileName,
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
        Logger.debug("Queue: Enqueue\n\(events.map({$0.event}))")
        inMemoryEvents.append(contentsOf: events)
        save(events: inMemoryEvents)
    }

    func first(limit: Int) -> [OptistreamEvent] {
        let amount = limit <= eventCount ? limit : eventCount
        /// TODO: remove from queue
        return Array(inMemoryEvents[0..<amount])
    }

    // success failure
    func remove(events: [OptistreamEvent]) {
        Logger.debug("Queue: Dequeue\n\(events.map({$0.event}))")
        /// TODO: add to queue
        inMemoryEvents = inMemoryEvents.filter { cachedEvent in
            !events.contains(cachedEvent) // O(n*n)
        }
        save(events: inMemoryEvents)
    }
}
