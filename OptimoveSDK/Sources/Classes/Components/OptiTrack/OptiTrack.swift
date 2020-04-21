//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class OptiTrack {

    private let configuration: OptitrackConfig
    private let eventReportingQueue: DispatchQueue
    private var tracker: Tracker

    required init(
        configuration: OptitrackConfig,
        tracker: Tracker) {
        self.configuration = configuration
        self.tracker = tracker
        self.eventReportingQueue = DispatchQueue(label: "com.optimove.sdk.optitrack", qos: .background)
        Logger.debug("OptiTrack initialized.")
        dispatchNow() // TODO: Delete it after queue with timer will be done.
    }

}

extension OptiTrack: Component {

    func handle(_ context: OperationContext) throws {
        switch context.operation {
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

    func report(event: OptimoveEvent) throws {
        Logger.debug("OptiTrack: Report event")
        let config = try event.matchConfiguration(with: configuration.events)
        eventReportingQueue.async { [tracker] in
            tracker.track(
                OptimoveEventDecorator(
                    event: event,
                    config: config
                )
            )
        }
    }

    func dispatchNow() {
        Logger.debug("OptiTrack: Dispatch now")
        tracker.dispatch()
    }

}
