//  Copyright © 2020 Optimove. All rights reserved.

final class OptistreamTracker {

    private let queue: OptistreamQueue
    private let optirstreamEventBuilder: OptistreamEventBuilder

    init(queue: OptistreamQueue,
         optirstreamEventBuilder: OptistreamEventBuilder) {
        self.queue = queue
        self.optirstreamEventBuilder = optirstreamEventBuilder
    }

}

extension OptistreamTracker: Tracker {

    func track(event: Event) {
        tryCatch {
            let event = try optirstreamEventBuilder.build(event: event)
            queue.enqueue(events: [event])
        }
    }

    func dispatch() {

    }

}

import OptimoveCore

protocol OptistreamQueue {
    var eventCount: Int { get }
    func enqueue(events: [OptistreamEvent])
    func first(limit: Int, completion: ([OptistreamEvent]) -> Void)
    func remove(events: [OptistreamEvent], completion: () -> Void)
}

final class OptistreamQueueImpl {

    private struct Constants {
        static let queuePersistanceFileName = "optistream_queue"
    }

    private let storage: OptimoveStorage
    private var cachedEvents = [OptistreamEvent]()

    init(storage: OptimoveStorage) {
        self.storage = storage

        /// TODO:  loadEventFromStorageToMemory()
    }

}

extension OptistreamQueueImpl: OptistreamQueue {

    var eventCount: Int {
        return cachedEvents.count
    }

    func enqueue(events: [OptistreamEvent]) {

    }

    func first(limit: Int, completion: ([OptistreamEvent]) -> Void) {

    }

    func remove(events: [OptistreamEvent], completion: () -> Void) {

    }
}
