//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class OptiTrack {

    private let configuration: OptitrackConfig
    private var storage: OptimoveStorage
    private let coreEventFactory: CoreEventFactory
    private let eventReportingQueue: DispatchQueue
    private var tracker: Tracker

    required init(
        configuration: OptitrackConfig,
        storage: OptimoveStorage,
        coreEventFactory: CoreEventFactory,
        tracker: Tracker) {
        self.configuration = configuration
        self.storage = storage
        self.coreEventFactory = coreEventFactory
        self.tracker = tracker
        self.eventReportingQueue = DispatchQueue(label: "com.optimove.sdk.optitrack", qos: .background)

        Logger.debug("OptiTrack initialized.")
        dispatchNow() // TODO: Delete it after queue with timer will be done.
    }

}

extension OptiTrack: Component {

    func handle(_ context: OperationContext) throws {
        switch context.operation {
        case .setUserId:
            try setUserId()
        case let .report(event: event):
            try report(event: event)
        case let .reportScreenEvent(title: pageTitle, category: category):
            try reportScreenEvent(title: pageTitle, category: category)
        case .dispatchNow:
            dispatchNow()
        default:
            break
        }
    }

}

private extension OptiTrack {

    func setUserId() throws {
        let userID = try storage.getCustomerID()
        Logger.info("OptiTrack: Set user id \(userID)")
        tracker.userId = userID
        try coreEventFactory.createEvent(.setUserId) { event in
            tryCatch { try self.report(event: event) }
        }
    }

    func report(event: OptimoveEvent) throws {
        let config = try event.matchConfiguration(with: configuration.events)
        guard config.supportedOnOptitrack else { return }
        eventReportingQueue.async {
            self.sendReport(
                event: OptimoveEventDecorator(
                    event: event,
                    config: config
                ),
                config: config
            )
        }
    }

    func reportScreenEvent(title: String, category: String?) throws {
        let categoryDescription: String = {
            guard let category = category else { return "" }
            return ", category: '\(category)'"
        }()
        Logger.debug("OptiTrack: Report screen event: title='\(title)'\(categoryDescription)")
        try coreEventFactory.createEvent(.pageVisit(title: title, category: category)) { event in
            tryCatch { try self.report(event: event) }
            self.tracker.track(view: [title], url: URL(string: PageVisitEvent.Constants.Value.customURL))
        }
    }

    func dispatchNow() {
        Logger.debug("OptiTrack: User asked to dispatch.")
        tracker.dispatch()
    }

}
