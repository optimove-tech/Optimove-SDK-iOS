//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
@testable import OptimoveSDK

final class MockTracker: Tracker {

    var userId: String?
    var forcedVisitorId: String?

    var trackEventAssertFunction: ((TrackerEvent) -> Void)?

    func track(_ event: TrackerEvent) {
        trackEventAssertFunction?(event)
    }

    var trackViewAssertFunction: (([String], URL?) -> Void)?

    func track(view: [String], url: URL?) {
        trackViewAssertFunction?(view, url)
    }

    var dispatchAssertFunction: (() -> Void)?

    func dispatch() {
        dispatchAssertFunction?()
    }

    var dispathPendingEventsAssertFunction: (() -> Void)?

    func dispathPendingEvents() {
        dispathPendingEventsAssertFunction?()
    }

}

