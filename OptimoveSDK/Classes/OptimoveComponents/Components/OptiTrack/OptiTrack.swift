//  Copyright © 2019 Optimove. All rights reserved.

import UIKit.UIApplication
import OptimoveCore

final class OptiTrack {

    struct Constants {
        struct AppOpen {
            // The threshold used for throttling emits an AppOpen event.
            static let throttlingThreshold: TimeInterval = 1_800 // 30 minutes.
        }
    }

    private let configuration: OptitrackConfig
    private var storage: OptimoveStorage
    private let coreEventFactory: CoreEventFactory
    private let dateTimeProvider: DateTimeProvider
    private var statisticService: StatisticService
    private let eventReportingQueue = DispatchQueue(label: "com.optimove.sdk.optitrack", qos: .background)
    private let deviceStateMonitor: OptimoveDeviceStateMonitor
    private var optimoveCustomizePlugins: [String: String] = [:]
    private var tracker: Tracker

    required init(
        configuration: OptitrackConfig,
        deviceStateMonitor: OptimoveDeviceStateMonitor,
        storage: OptimoveStorage,
        coreEventFactory: CoreEventFactory,
        dateTimeProvider: DateTimeProvider,
        statisticService: StatisticService,
        trackerFlagsBuilder: TrackerFlagsBuilder,
        tracker: Tracker) {
        self.configuration = configuration
        self.storage = storage
        self.coreEventFactory = coreEventFactory
        self.dateTimeProvider = dateTimeProvider
        self.statisticService = statisticService
        self.deviceStateMonitor = deviceStateMonitor
        self.tracker = tracker
        self.optimoveCustomizePlugins = (try? trackerFlagsBuilder.build()) ?? [:]

        performInitializationOperations()
        Logger.debug("OptiTrack initialized.")
    }

    // MARK: - Internal Methods

    func performInitializationOperations() {
        do {
            injectVisitorAndUserIdToMatomo()
            reportPendingEvents()
            try reportMetaData()
            reportIdfaIfAllowed()
            try reportUserAgent()
            reportOptInOutIfNeeded()
            try reportAppOpenedIfNeeded()
            trackAppOpened()
            observeEnterToBackgroundMode()
        } catch {
            Logger.error(error.localizedDescription)
        }
    }

}

extension OptiTrack: EventableComponent {

    func handleEventable(_ context: EventableOperationContext) throws {
        switch context.operation {
        case let .setUserId(userId: userId):
            setUserId(userId)
        case let .report(event: event):
            try report(event: event)
        case let .reportScreenEvent(customURL: customURL, pageTitle: pageTitle, category: category):
            try reportScreenEvent(customURL: customURL, pageTitle: pageTitle, category: category)
        case .dispatchNow:
            dispatchNow()
        }
    }

}

private extension OptiTrack {

    func setUserId(_ userId: String) {
        Logger.info("OptiTrack: Set user id \(userId)")
        tracker.userId = userId
    }

    func report(event: OptimoveEvent) throws {
        let pair = try event.matchConfiguration(with: configuration.events)
        guard pair.config.supportedOnOptitrack else { return }
        eventReportingQueue.async {
            self.sendReport(event: OptimoveEventDecorator(event: pair.event, config: pair.config), config: pair.config)
        }
    }

    func reportScreenEvent(customURL: String, pageTitle: String, category: String?) throws {
        Logger.debug("OptiTrack: Report screen event: title='\(pageTitle)', path='\(customURL)'")
        tracker.track(view: [pageTitle], url: URL(string: "http://\(customURL)"))

        let event = try coreEventFactory.createEvent(
            .pageVisit(screenPath: customURL.sha1(),
                       screenTitle: pageTitle,
                       category: category
            )
        )
        try report(event: event)
    }

    func dispatchNow() {
        Logger.debug("OptiTrack: User asked to dispatch.")
        tracker.dispatch()
    }

    // MARK: - Report

    func obtainConfiguration(for event: OptimoveEvent) throws -> EventsConfig {
        guard let config = configuration.events[event.name] else {
            throw GuardError.custom("Configurations are missing for event \(event.name)")
        }
        return config
    }

}

// ELI: Changed access level for extension for tests purposes.
extension OptiTrack {

    func injectVisitorAndUserIdToMatomo() {
        if let globalVisitorID = storage.visitorID {
            let localVisitorID: String? = tracker.forcedVisitorId
            if localVisitorID != globalVisitorID {
                tracker.forcedVisitorId = globalVisitorID
            }
        }
        if let globalUserID = storage.customerID {
            let localUserID: String? = tracker.userId
            if localUserID != globalUserID {
                setUserId(globalUserID)
            }
        }
    }

    func observeEnterToBackgroundMode() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: self,
            queue: .main
        ) { (_) in
            self.dispatchNow()
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
            dimensions: parameterDimensions + nameDimensions,
            customTrackingParameters: self.optimoveCustomizePlugins
        )
        tracker.track(event)

        // ELI: TODO: Check this point out.
        if config.supportedOnRealTime {
            self.dispatchNow()
        }
    }

    func reportIdfaIfAllowed() {
        guard configuration.enableAdvertisingIdReport == true else { return }
        do {
            let event = try coreEventFactory.createEvent(.setAdvertisingId)
            try self.report(event: event)
        } catch {
            Logger.error(error.localizedDescription)
        }
    }

    func reportUserAgent() throws {
        let event = try coreEventFactory.createEvent(.setUserAgent)
        try report(event: event)
    }

    func reportMetaData() throws {
        let event = try coreEventFactory.createEvent(.metaData)
        try report(event: event)
    }

    func reportAppOpenedIfNeeded() throws {
        DispatchQueue.main.async {
            if UIApplication.shared.applicationState != .background {
                DispatchQueue.global().async { [weak self] in
                    do {
                        try self?.reportAppOpen()
                    } catch {
                        Logger.error(error.localizedDescription)
                    }
                }
            }
        }
    }

    func isOptStateChanged(with newState: Bool) -> Bool {
        let isOptiTrackOptIn: Bool = storage.isOptiTrackOptIn
        return newState != isOptiTrackOptIn
    }

    func reportOptInOutIfNeeded() {
        deviceStateMonitor.getStatus(for: .userNotification) { [coreEventFactory] (granted) in
            guard self.isOptStateChanged(with: granted) else {
                // An OptIn/OptOut state was not changed.
                return
            }
            do {
                if granted {
                    let event = try coreEventFactory.createEvent(.optipushOptIn)
                    try self.report(event: event)
                    self.storage.isOptiTrackOptIn = true
                } else {
                    let event = try coreEventFactory.createEvent(.optipushOptOut)
                    try self.report(event: event)
                    self.storage.isOptiTrackOptIn = false
                }
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
    }

    func trackAppOpened() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] (_) in
            do {
                try self?.handleWillEnterForegroundNotification()
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
    }

    func handleWillEnterForegroundNotification() throws {
        let threshold: TimeInterval = Constants.AppOpen.throttlingThreshold
        let now = dateTimeProvider.now.timeIntervalSince1970
        let appOpenTime = statisticService.applicationOpenTime
        if (now - appOpenTime) > threshold {
            try reportAppOpen()
        }
    }

    func reportPendingEvents() {
        tracker.dispathPendingEvents()
    }

    func reportAppOpen() throws {
        let event = try coreEventFactory.createEvent(.appOpen)
        try report(event: event)
        statisticService.applicationOpenTime = dateTimeProvider.now.timeIntervalSince1970
    }
}
