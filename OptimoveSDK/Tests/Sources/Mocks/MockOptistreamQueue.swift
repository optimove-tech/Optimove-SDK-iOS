//  Copyright © 2020 Optimove. All rights reserved.

import OptimoveCore
@testable import OptimoveSDK

final class MockOptistreamQueue: OptistreamQueue {
    var events: [OptistreamEvent] = []

    var isEmpty: Bool {
        return events.isEmpty
    }

    func enqueue(events: [OptistreamEvent]) {
        self.events.append(contentsOf: events)
    }

    func first(limit: Int) -> [OptistreamEvent] {
        let amount = limit <= events.count
            ? limit : events.count
        return Array(events[0 ..< amount])
    }

    func remove(events: [OptistreamEvent]) {
        self.events = self.events.filter { cachedEvent in
            !events.contains(cachedEvent) // O(n*n)
        }
    }
}
