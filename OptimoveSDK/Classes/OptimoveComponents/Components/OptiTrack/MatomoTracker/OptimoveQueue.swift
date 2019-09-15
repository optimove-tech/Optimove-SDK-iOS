//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import MatomoTracker
import OptimoveCore

final class OptimoveQueue {

    private let storage: OptimoveStorage
    private var cachedEvents = [Event]()

    init(storage: OptimoveStorage) {
        self.storage = storage

        cachedEvents = loadEventFromStorageToMemory()
    }

    private func loadEventFromStorageToMemory() -> [Event] {
        guard storage.isExist(fileName: TrackerConstants.pendingEventsFile,
                              shared: TrackerConstants.isSharedStorage) else { return [] }
        do {
            let jsonEvents = try storage.load(
                fileName: TrackerConstants.pendingEventsFile,
                shared: TrackerConstants.isSharedStorage
            )
            let decoder = JSONDecoder()
            return try decoder.decode([Event].self, from: jsonEvents)
        } catch {
            Logger.error(error.localizedDescription)
            return []
        }
    }

}

extension OptimoveQueue: Queue {

    var eventCount: Int {
        return cachedEvents.count
    }

    func enqueue(events: [Event], completion: (() -> Void)?) {
        Logger.debug("OptimoveQueue: Enqueue")
        cachedEvents.append(contentsOf: events)
        do {
            try storage.save(
                data: cachedEvents,
                toFileName: TrackerConstants.pendingEventsFile,
                shared: TrackerConstants.isSharedStorage
            )
        } catch {
            Logger.error("OptimoveQueue: Events file could not be saved. Reason: \(error.localizedDescription)")
        }
        completion?()
    }

    func first(limit: Int, completion: ([Event]) -> Void) {
        let amount = limit <= eventCount ? limit : eventCount
        let dequeuedItems = Array(cachedEvents[0..<amount])
        completion(dequeuedItems)
    }

    func remove(events: [Event], completion: () -> Void) {
        Logger.debug("OptimoveQueue: Dequeue")
        cachedEvents = cachedEvents.filter { cachedEvent in
            !events.contains(cachedEvent)
        }
        do {
            try storage.save(
                data: cachedEvents,
                toFileName: TrackerConstants.pendingEventsFile,
                shared: TrackerConstants.isSharedStorage
            )
        } catch {
            Logger.error("OptimoveQueue: Events file could not be saved. Reason: \(error.localizedDescription)")
        }
        completion()
    }
}

extension Event: Equatable {

    public static func == (lhs: Event, rhs: Event) -> Bool {
        return lhs.uuid == rhs.uuid
    }

}
