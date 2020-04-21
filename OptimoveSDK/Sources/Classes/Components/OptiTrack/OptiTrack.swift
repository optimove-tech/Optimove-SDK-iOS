//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class OptiTrack {

    private var tracker: Tracker

    init(tracker: Tracker) {
        self.tracker = tracker
        Logger.debug("OptiTrack initialized.")
        dispatchNow() // TODO: Delete it after queue with timer will be done.
    }

}

extension OptiTrack: Component {

    func handle(_ operation: Operation) throws {
        switch operation {
        case let .report(event: event):
            try report(event: event)
        case .dispatchNow:
            dispatchNow()
        default:
            break
        }
    }

}

private extension OptiTrack {

    func report(event: Event) throws {
        Logger.debug("OptiTrack: Report event")
        tracker.track(event: event)
    }

    func dispatchNow() {
        Logger.debug("OptiTrack: Dispatch now")
        tracker.dispatch()
    }

}
