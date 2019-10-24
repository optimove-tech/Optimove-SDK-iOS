//  Copyright © 2019 Optimove. All rights reserved.

import UIKit.UIApplication
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
        syncVisitorAndUserIdToMatomo()
        dispatchNow()
    }

}

extension OptiTrack: Component {

    func handle(_ context: OperationContext) throws {
        switch context.operation {
        case let .eventable(operation):
            switch operation {
            case .setUserId:
                try setUserId()
            case let .report(event: event):
                try report(event: event)
            case let .reportScreenEvent(customURL: customURL, pageTitle: pageTitle, category: category):
                try reportScreenEvent(customURL: customURL, pageTitle: pageTitle, category: category)
            case .dispatchNow:
                dispatchNow()
            }
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
        try report(event: try coreEventFactory.createEvent(.setUserId))
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

    func reportScreenEvent(customURL: String, pageTitle: String, category: String?) throws {
        let categoryDescription: String = {
            guard let category = category else { return "" }
            return ", category: '\(category)'"
        }()
        Logger.debug("OptiTrack: Report screen event: title='\(pageTitle)', path='\(customURL)'\(categoryDescription)")
        let event = try coreEventFactory.createEvent(
            .pageVisit(
                screenPath: customURL.sha1(),
                screenTitle: pageTitle,
                category: category
            )
        )
        try report(event: event)
        tracker.track(view: [pageTitle], url: URL(string: "http://\(customURL)"))
    }

    func dispatchNow() {
        Logger.debug("OptiTrack: User asked to dispatch.")
        tracker.dispatch()
    }

}

extension OptiTrack {

    func syncVisitorAndUserIdToMatomo() {
        if let globalVisitorID = storage.visitorID {
            let localVisitorID: String? = tracker.forcedVisitorId
            if localVisitorID != globalVisitorID {
                tracker.forcedVisitorId = globalVisitorID
            }
        }
        if let globalUserID = storage.customerID {
            let localUserID: String? = tracker.userId
            if localUserID != globalUserID {
                tryCatch { try setUserId() }
            }
        }
    }

    func sendReport(event: OptimoveEvent, config: EventsConfig) {
        let customDimensionIDS = configuration.customDimensionIDS
        let maxCustomDimensions = customDimensionIDS.maxActionCustomDimensions + customDimensionIDS.maxVisitCustomDimensions

        let getOptitrackDimensionId: (String) -> Int? = { parameterName in
            return config.parameters[parameterName]?.optiTrackDimensionId
        }

        let parameterDimensions: [TrackerEvent.CustomDimension] = event.parameters
            .compactMapKeys(getOptitrackDimensionId)
            .filter { $0.key <= maxCustomDimensions }
            .mapValues { String(describing: $0).trimmingCharacters(in: .whitespaces) }
            .map { TrackerEvent.CustomDimension(index: $0.key, value: $0.value) }

        let nameDimensions: [TrackerEvent.CustomDimension] = [
            TrackerEvent.CustomDimension(index: customDimensionIDS.eventIDCustomDimensionID, value: String(config.id)),
            TrackerEvent.CustomDimension(index: customDimensionIDS.eventNameCustomDimensionID, value: event.name)
        ]

        let event = TrackerEvent(
            category: configuration.eventCategoryName,
            action: event.name,
            dimensions: parameterDimensions + nameDimensions
        )
        tracker.track(event)
    }

}
