//  Copyright © 2017 Optimove

import UIKit

final class OptiTrack: OptimoveComponent {

    struct Constants {
        struct AppOpen {
            // The threshold used for throttling emits an AppOpen event.
            static let throttlingThreshold: TimeInterval = 1800 // 30 minutes.
        }
    }

    private let warehouseProvider: EventsConfigWarehouseProvider
    private var storage: OptimoveStorage
    private let metaDataProvider: MetaDataProvider<OptitrackMetaData>
    private let coreEventFactory: CoreEventFactory
    private let dateTimeProvider: DateTimeProvider
    private let statisticService: StatisticService
    private let eventReportingQueue = DispatchQueue(label: "com.optimove.optitrack", qos: .background)
    private let optimoveCustomizePlugins: [String: String]

    // TODO: Make private after resolve construction lifecycle.
    var tracker: Tracker?
    private var lastReportedOpenApplicationTime: TimeInterval?

    required init(
        deviceStateMonitor: OptimoveDeviceStateMonitor,
        warehouseProvider: EventsConfigWarehouseProvider,
        storage: OptimoveStorage,
        metaDataProvider: MetaDataProvider<OptitrackMetaData>,
        coreEventFactory: CoreEventFactory,
        dateTimeProvider: DateTimeProvider,
        statisticService: StatisticService,
        trackerFlagsBuilder: TrackerFlagsBuilder) {
        self.warehouseProvider = warehouseProvider
        self.storage = storage
        self.metaDataProvider = metaDataProvider
        self.coreEventFactory = coreEventFactory
        self.dateTimeProvider = dateTimeProvider
        self.statisticService = statisticService
        self.optimoveCustomizePlugins = (try? trackerFlagsBuilder.build()) ?? [:]
        super.init(deviceStateMonitor: deviceStateMonitor)
    }

    // MARK: - Internal Methods

    override func performInitializationOperations() {
        guard RunningFlagsIndication.isComponentRunning(.optiTrack) else { return }
        do {
            lastReportedOpenApplicationTime = dateTimeProvider.now.timeIntervalSince1970
            injectVisitorAndUserIdToMatomo()
            reportPendingEvents()
            try reportMetaData()
            try reportIdfaIfAllowed()
            try reportUserAgent()
            reportOptInOutIfNeeded()
            try reportAppOpenedIfNeeded()
            trackAppOpened()
            observeEnterToBackgroundMode()
        } catch {
            OptiLoggerMessages.logError(error: error)
        }
    }

    func setupTracker() throws {
        tracker = try MatomoTrackerAdapter(
            metaData: try metaDataProvider.getMetaData(),
            storage: storage
        )
    }
}

extension OptiTrack {

    // MARK: - Report

    func report(event: OptimoveEvent) {
        let warehouse = try? warehouseProvider.getWarehouse()
        let event = OptimoveEventDecorator(event: event)
        guard let config = warehouse?.getConfig(for: event) else {
            OptiLoggerMessages.logConfugurationForEventMissing(eventName: event.name)
            return
        }
        OptiLoggerMessages.logOptitrackReport(event: event.name)
        event.processEventConfig(config)
        report(event: event, withConfigs: config)
    }


    func report(event: OptimoveEvent, withConfigs config: EventsConfig) {
        eventReportingQueue.async {
            do {
                try self.sendReport(event: event, config: config)
            } catch {
                OptiLoggerMessages.logError(error: error)
            }
        }
    }

    func reportScreenEvent(screenTitle: String,
                           screenPath: String,
                           category: String? = nil) throws {
        OptiLoggerMessages.logReportScreenEvent(screenTitle: screenTitle)
        tracker?.track(view: [screenTitle], url: URL(string: "http://\(screenPath)"))

        let event = try coreEventFactory.createEvent(
            .pageVisit(screenPath: screenPath.sha1(),
                       screenTitle: screenTitle,
                       category: category
            )
        )
        report(event: event)
    }

    func setUserId(_ userId: String) {
        OptiLoggerMessages.logOptitrackSetUserID(userId: userId)
        tracker?.userId = userId
    }

    // MARK: - Dispatch

    func dispatchNow() {
        if RunningFlagsIndication.isComponentRunning(.optiTrack) {
            OptiLoggerMessages.logOptitrackDispatchRequest()
            tracker?.dispatch()
        } else {
            OptiLoggerMessages.logOptitrackNotRunning()
        }
    }
}


// ELI: Changed access level for extension for tests purposes.
extension OptiTrack {

    func injectVisitorAndUserIdToMatomo() {
        if let globalVisitorID = storage.visitorID {
            let localVisitorID: String? = tracker?.forcedVisitorId
            if localVisitorID != globalVisitorID {
                tracker?.forcedVisitorId = globalVisitorID
            }
        }
        if let globalUserID = storage.customerID {
            let localUserID: String? = tracker?.userId
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

    func sendReport(event: OptimoveEvent, config: EventsConfig) throws {
        let metaData = try metaDataProvider.getMetaData()
        let maxCustomDimensions = metaData.maxActionCustomDimensions + metaData.maxVisitCustomDimensions

        let getOptitrackDimensionId: (String) -> Int? = { parameterName in
            return config.parameters[parameterName]?.optiTrackDimensionId
        }

        let dimensions: [TrackerEvent.CustomDimension] = event.parameters
            .compactMapKeys(getOptitrackDimensionId)
            .filter { $0.key <= maxCustomDimensions }
            .mapValues { String(describing: $0).trimmingCharacters(in: .whitespaces) }
            .map { TrackerEvent.CustomDimension(index: $0.key, value: $0.value) }

        let metadataDimensions: [TrackerEvent.CustomDimension] = [
            TrackerEvent.CustomDimension(index: metaData.eventIdCustomDimensionId, value: String(config.id)),
            TrackerEvent.CustomDimension(index: metaData.eventNameCustomDimensionId, value: event.name)
        ]

        let event = TrackerEvent(
            category: metaData.eventCategoryName,
            action: event.name,
            dimensions: dimensions + metadataDimensions,
            customTrackingParameters: self.optimoveCustomizePlugins
        )
        self.tracker?.track(event)
        
        // ELI: TODO: Check this point out.
        if config.supportedOnRealTime {
            self.deviceStateMonitor.getStatus(for: .internet) { (hasInternet) in
                if hasInternet {
                    self.dispatchNow()
                }
            }
        }
    }

    func reportIdfaIfAllowed() throws {
        let metaData = try metaDataProvider.getMetaData()
        guard metaData.enableAdvertisingIdReport == true else { return }
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
        let appOpenTime = lastReportedOpenApplicationTime ?? statisticService.applicationOpenTime
        if (now - appOpenTime) > threshold {
            try reportAppOpen()
        }
    }

    func reportPendingEvents() {
        if RunningFlagsIndication.isComponentRunning(.optiTrack) {
            tracker?.dispathPendingEvents()
        }
    }

    func reportAppOpen() throws {
        let event = try coreEventFactory.createEvent(.appOpen)
        report(event: event)
        lastReportedOpenApplicationTime = dateTimeProvider.now.timeIntervalSince1970
    }
}
