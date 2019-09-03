//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import MatomoTracker
import OptimoveCore

final class MatomoTrackerAdapter {

    private struct Constants {
        static let piwikPath = "piwik.php"
    }

    private let tracker: MatomoTracker
    private var storage: OptimoveStorage

    init(configuration: OptitrackConfig,
         storage: OptimoveStorage) {
        self.storage = storage
        let baseURL: URL = {
            if !configuration.optitrackEndpoint.absoluteString.contains(Constants.piwikPath) {
                return configuration.optitrackEndpoint.appendingPathComponent(Constants.piwikPath)
            }
            return configuration.optitrackEndpoint
        }()
        self.tracker = MatomoTracker(
            siteId: String(configuration.tenantID),
            queue: OptimoveQueue(
                storage: storage
            ),
            dispatcher: URLSessionDispatcher(
                baseURL: baseURL
            )
        )
        setupForNotificationExtension()
    }

    private func setupForNotificationExtension() {
        let screenSize = Device.makeCurrentDevice().screenSize
        storage.deviceResolutionHeight = Float(screenSize.height)
        storage.deviceResolutionWidth = Float(screenSize.width)
    }

    private func convertToMatomoEvent(_ event: TrackerEvent) -> Event {
        return Event(
            tracker: tracker,
            action: [],
            eventCategory: event.category,
            eventAction: event.action,
            customTrackingParameters: event.customTrackingParameters,
            dimensions: event.dimensions.map { CustomDimension(index: $0.index, value: $0.value) }
        )
    }
}

extension MatomoTrackerAdapter: Tracker {

    var userId: String? {
        get {
            return tracker.userId
        }
        set {
            tracker.userId = newValue
        }
    }

    var forcedVisitorId: String? {
        get {
            return tracker.forcedVisitorId
        }
        set {
            tracker.forcedVisitorId = newValue
        }
    }

    func track(_ event: TrackerEvent) {
        tracker.track(convertToMatomoEvent(event))
    }

    func track(view: [String], url: URL?) {
        tracker.track(view: view, url: url)
    }

    func dispatch() {
        tracker.dispatch()
    }

    func dispathPendingEvents() {
        do {
            let jsonEvents = try storage.load(
                fileName: TrackerConstants.pendingEventsFile,
                shared: false
            )
            let decoder = JSONDecoder()
            let events = try decoder.decode([Event].self, from: jsonEvents)

            //Since all stored events are already matomo events type, no need to do the entire process
            events.forEach { (event) in
                tracker.track(event)
            }
        } catch {
            Logger.error(error.localizedDescription)
        }
    }

}
