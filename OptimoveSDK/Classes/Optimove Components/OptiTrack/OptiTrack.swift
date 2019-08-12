//  Copyright © 2017 Optimove

import UIKit
import OptimoveCore

final class OptiTrack {

    struct Constants {
        struct AppOpen {
            // The threshold used for throttling emits an AppOpen event.
            static let throttlingThreshold: TimeInterval = 1800 // 30 minutes.
        }
    }

    private let configuration: OptitrackConfig
    private var storage: OptimoveStorage
    private let coreEventFactory: CoreEventFactory
    private let dateTimeProvider: DateTimeProvider
    private var statisticService: StatisticService
    private let eventReportingQueue = DispatchQueue(label: "com.optimove.optitrack", qos: .background)
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
        tracker: Tracker) {
        self.configuration = configuration
        self.storage = storage
        self.coreEventFactory = coreEventFactory
        self.dateTimeProvider = dateTimeProvider
        self.statisticService = statisticService
        self.deviceStateMonitor = deviceStateMonitor
        self.tracker = tracker
        optimoveCustomizePlugins = createPluginFlags()

        performInitializationOperations()
    }

    // MARK: - Internal Methods

    func performInitializationOperations() {
        guard RunningFlagsIndication.isComponentRunning(.optiTrack) else { return }
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
            OptiLoggerMessages.logError(error: error)
        }
    }
}

extension OptiTrack: Eventable {

    func setUserId(_ userId: String) {
        OptiLoggerMessages.logOptitrackSetUserID(userId: userId)
        tracker.userId = userId
    }

    func report(event: OptimoveEvent, config: EventsConfig) {
        guard config.supportedOnOptitrack else { return }
        eventReportingQueue.async {
            self.sendReport(event: event, config: config)
        }
    }

    func reportScreenEvent(customURL: String, pageTitle: String, category: String?) throws {
        OptiLoggerMessages.logReportScreenEvent(screenTitle: pageTitle)
        tracker.track(view: [customURL], url: URL(string: "http://\(customURL)"))

        let event = try coreEventFactory.createEvent(
            .pageVisit(screenPath: customURL.sha1(),
                       screenTitle: pageTitle,
                       category: category
            )
        )
        report(event: event)
    }

    func dispatchNow() {
        if RunningFlagsIndication.isComponentRunning(.optiTrack) {
            OptiLoggerMessages.logOptitrackDispatchRequest()
            tracker.dispatch()
        } else {
            OptiLoggerMessages.logOptitrackNotRunning()
        }
    }

}

extension OptiTrack {

    // MARK: - Report

    func report(event: OptimoveEvent) {
        let event = OptimoveEventDecorator(event: event)
        guard let config = configuration.events[event.name] else {
            OptiLoggerMessages.logConfugurationForEventMissing(eventName: event.name)
            return
        }
        OptiLoggerMessages.logOptitrackReport(event: event.name)
        event.processEventConfig(config)
        report(event: event, config: config)
    }

    func reportScreenEvent(screenTitle: String,
                           screenPath: String,
                           category: String? = nil) throws {
        OptiLoggerMessages.logReportScreenEvent(screenTitle: screenTitle)
        tracker.track(view: [screenTitle], url: URL(string: "http://\(screenPath)"))

        let event = try coreEventFactory.createEvent(
            .pageVisit(screenPath: screenPath.sha1(),
                       screenTitle: screenTitle,
                       category: category
            )
        )
        report(event: event)
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

    func createPluginFlags() -> [String: String] {
        guard let initialVisitorId: String = storage[.initialVisitorId] else { return [:] }
        let pluginFlags = ["fla", "java", "dir", "qt", "realp", "pdf", "wma", "gears"]
        let pluginValues = initialVisitorId.split(by: 2)
            .map { Int($0, radix: 16)! / 2 }
            .map { $0.description }

        return Dictionary(uniqueKeysWithValues: zip(pluginFlags, pluginValues))
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
            self.deviceStateMonitor.getStatus(for: .internet) { (hasInternet) in
                if hasInternet {
                    self.dispatchNow()
                }
            }
        }
    }

    func reportIdfaIfAllowed() {
        guard configuration.enableAdvertisingIdReport == true else { return }
        deviceStateMonitor.getStatus(for: .advertisingId) { [coreEventFactory] (isAllowed) in
            guard isAllowed else { return }
            do {
                let event = try coreEventFactory.createEvent(.setAdvertisingId)
                self.report(event: event)
            } catch {
                OptiLoggerMessages.logError(error: error)
            }
        }
    }

    func reportUserAgent() throws {
        let event = try coreEventFactory.createEvent(.setUserAgent)
        report(event: event)
    }

    func reportMetaData() throws {
        let event = try coreEventFactory.createEvent(.metaData)
        report(event: event)
    }

    func reportAppOpenedIfNeeded() throws {
        if UIApplication.shared.applicationState != .background {
            try reportAppOpen()
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
                    self.report(event: event)
                    self.storage.isOptiTrackOptIn = true
                } else {
                    let event = try coreEventFactory.createEvent(.optipushOptOut)
                    self.report(event: event)
                    self.storage.isOptiTrackOptIn = false
                }
            } catch {
                OptiLoggerMessages.logError(error: error)
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
                OptiLoggerMessages.logError(error: error)
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
        if RunningFlagsIndication.isComponentRunning(.optiTrack) {
            tracker.dispathPendingEvents()
        }
    }

    func reportAppOpen() throws {
        let event = try coreEventFactory.createEvent(.appOpen)
        report(event: event)
        statisticService.applicationOpenTime = dateTimeProvider.now.timeIntervalSince1970
    }
}
