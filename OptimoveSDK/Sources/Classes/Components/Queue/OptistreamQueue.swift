//  Copyright © 2020 Optimove. All rights reserved.

import CoreData
import Foundation
import OptimoveCore

enum OptistreamQueueType: String {
    case realtime
    case track
}

protocol OptistreamQueue {
    var isEmpty: Bool { get }
    func enqueue(events: [OptistreamEvent])
    func first(limit: Int) -> [OptistreamEvent]
    func remove(events: [OptistreamEvent])
}
