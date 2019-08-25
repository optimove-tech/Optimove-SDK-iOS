//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

struct TrackerConstants {
    static let pendingEventsFile = "pendingOptimoveEvents.json"
    static let isSharedStorage = false
}

protocol Tracker {
    var userId: String? { get set }
    var forcedVisitorId: String? { get set }

    func track(_ event: TrackerEvent)
    func track(view: [String], url: URL?)

    func dispatch()
    func dispathPendingEvents()
}

extension Tracker {

    func track(view: [String], url: URL? = nil) {
        track(view: view, url: url)
    }

}

struct TrackerEvent: Codable {
    /// Event tracking
    let category: String
    let action: String

    let dimensions: [CustomDimension]

    let customTrackingParameters: [String: String]
}

extension TrackerEvent {
    struct CustomDimension: Codable {
        /// The index of the dimension.
        let index: Int

        /// The value you want to set for this dimension.
        let value: String
    }
}
