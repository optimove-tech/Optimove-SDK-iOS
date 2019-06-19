//
//  Optitrack.swift
//  iOS-SDK
//
//  Created by Mobile Developer Optimove on 04/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation
import OptiTrackCore

final class OptiTrack: OptimoveComponent {
    // MARK: - Internal Variables
    var metaData: OptitrackMetaData!
    var queue = OptimoveQueue()
    var tracker: MatomoTracker!

    private let evetReportingQueue = DispatchQueue(
        label: "com.optimove.optitrack",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .inherit,
        target: nil
    )
    var openApplicationTime: TimeInterval = Date().timeIntervalSince1970
    private var optimoveCustomizePlugins: [String: String] = [:]

    override init(deviceStateMonitor: OptimoveDeviceStateMonitor) {
        super.init(deviceStateMonitor: deviceStateMonitor)
        setupPluginFlags()
    }

    // MARK: - Internal Methods
    func injectVisitorAndUserIdToMatomo() {
        tracker.visitorId = OptimoveUserDefaults.shared.visitorID!
        if let customerId = CustomerID {
            guard let trackerUserId = tracker.userId else {
                //Conversion missed
                let event = SetUserId(
                    originalVistorId: OptimoveUserDefaults.shared.initialVisitorId!,
                    userId: customerId,
                    updateVisitorId: OptimoveUserDefaults.shared.visitorID!
                )
                setUserId(event.userId)
                return
            }
            guard trackerUserId != customerId else { return }
            let ovid = SHA1.hexString(from: trackerUserId)!.replacingOccurrences(of: " ", with: "").prefix(
                16
            ).description
            let event = SetUserId(
                originalVistorId: ovid,
                userId: trackerUserId,
                updateVisitorId: OptimoveUserDefaults.shared.visitorID!
            )
            setUserId(event.userId)
        }
    }

    override func performInitializationOperations() {
        if RunningFlagsIndication.isComponentRunning(.optiTrack) {
            self.injectVisitorAndUserIdToMatomo()
            self.reportPendingEvents()
            self.reportSdkVersion()
            self.reportIdfaIfAllowed()
            self.reportUserAgent()
            self.reportOptInOutIfNeeded()
            self.reportAppOpenedIfNeeded()
            self.trackAppOpened()
            self.observeEnterToBackgroundMode()
        }
    }

    private func observeEnterToBackgroundMode() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: self,
            queue: .main
        ) { (_) in
            self.dispatchNow()
        }
    }
}

extension OptiTrack {
    func report(event: OptimoveEventDecorator, withConfigs config: OptimoveEventConfig) {
        if event is OptimoveCustomEventDecorator {
            guard isEnable else {
                OptiLoggerMessages.logOptiTrackDisable()
                return
            }
        }
        evetReportingQueue.async {
            self.handleReport(event: event, withConfigs: config)
        }
    }

    private func setupPluginFlags() {
        let pluginFlags = ["fla", "java", "dir", "qt", "realp", "pdf", "wma", "gears"]
        let pluginValues = OptimoveUserDefaults.shared.initialVisitorId!.splitedBy(length: 2).map {
            Int($0, radix: 16)!/2
        }.map { $0.description }
        for i in 0..<pluginFlags.count {
            let pluginFlag = pluginFlags[i]
            let pluginValue = pluginValues[i]
            self.optimoveCustomizePlugins[pluginFlag] = pluginValue
        }
    }

    private func handleReport(
        event: OptimoveEventDecorator,
        withConfigs config: OptimoveEventConfig,
        completionHandler: (() -> Void)? = nil
    ) {
        DispatchQueue.main.async {
            var dimensions: [CustomDimension] = [
                CustomDimension(index: self.metaData.eventIdCustomDimensionId, value: String(config.id)),
                CustomDimension(index: self.metaData.eventNameCustomDimensionId, value: event.name)
            ]
            for (name, value) in event.parameters {
                if let optitrackDimensionID = config.parameters[name]?.optiTrackDimensionId {
                    if optitrackDimensionID <= (
                        self.metaData.maxActionCustomDimensions + self.metaData.maxVisitCustomDimensions
                    ) {
                        let truncatedValue = (String(describing: value).trimmingCharacters(in: .whitespaces))
                        if !truncatedValue.isEmpty {
                            dimensions.append(
                                CustomDimension(index: optitrackDimensionID, value: String(describing: truncatedValue))
                            )
                        }
                    }
                }
            }
            let event = Event(
                tracker: self.tracker,
                action: [],
                url: nil,
                referer: nil,
                eventCategory: self.metaData.eventCategoryName,
                eventAction: event.name,
                eventName: nil,
                eventValue: nil,
                customTrackingParameters: self.optimoveCustomizePlugins,
                dimensions: dimensions,
                variables: []
            )
            self.tracker.track(event)
            if config.supportedOnRealTime {
                self.deviceStateMonitor.getStatus(
                    of: .internet,
                    completionHandler: { (hasInternet) in
                        if hasInternet {
                            self.dispatchNow()
                        }
                    }
                )
            }
            completionHandler?()
        }
    }

    func reportScreenEvent(screenTitle: String, screenPath: String, category: String? = nil) {
        evetReportingQueue.async {
            //            let updatedScreenPath = "\(Bundle.main.bundleIdentifier!)/\(screenPath)".lowercased()
            OptiLoggerMessages.logReportScreenEvent(screenTitle: screenTitle)
            DispatchQueue.main.async {
                self.tracker?.track(view: [screenTitle], url: URL(string: "http://\(screenPath)"))

                let originalEvent = PageVisitEvent(
                    customURL: SHA1.hexString(from: screenPath)!.replacingOccurrences(of: " ", with: ""),
                    pageTitle: screenTitle,
                    category: category
                )
                let event = OptimoveEventDecorator(event: originalEvent)

                guard let config = Optimove.shared.eventWarehouse?.getConfig(ofEvent: event) else {
                    OptiLoggerMessages.logConfugurationForEventMissing(eventName: event.name)
                    return
                }
                event.processEventConfig(config)
                self.report(event: event, withConfigs: config)
            }
        }
    }

    func setUserId(_ userId: String) {
        OptiLoggerMessages.logOptitrackSetUserID(userId: userId)
        self.tracker.userId = userId
    }

    func dispatchNow() {
        if RunningFlagsIndication.isComponentRunning(.optiTrack) {
            OptiLoggerMessages.logOptitrackDispatchRequest()
            tracker.dispatch()
        } else {
            OptiLoggerMessages.logOptitrackNotRunning()
        }
    }

    private func reportIdfaIfAllowed() {
        guard metaData.enableAdvertisingIdReport == true else { return }
        self.deviceStateMonitor.getStatus(of: .advertisingId) { (isAllowed) in
            if isAllowed {
                let event = SetAdvertisingId()
                if let config = Optimove.shared.eventWarehouse?.getConfig(ofEvent: event) {
                    OptiLoggerMessages.logOptitrackReport(event: "IDFA")
                    let dec = OptimoveEventDecorator(event: event, config: config)
                    self.report(event: dec, withConfigs: config)
                } else {
                    OptiLoggerMessages.logLoadingConfigsError(ofEvent: "IDFA")
                }
            }
        }
    }

    private func reportUserAgent() {
        let userAgent = Device.evaluateUserAgent()
        OptimoveUserDefaults.shared.userAgent = userAgent
        let event = SetUserAgent(userAgent: userAgent)
        if let config = Optimove.shared.eventWarehouse?.getConfig(ofEvent: event) {
            OptiLoggerMessages.logOptitrackReport(event: "User Agent")
            let dec = OptimoveEventDecorator(event: event, config: config)
            report(event: dec, withConfigs: config)
        } else {
            OptiLoggerMessages.logLoadingConfigsError(ofEvent: "User Agent")
        }
    }

    fileprivate func getFullConfigurationPath() -> String {
        return OptimoveUserDefaults.shared.configurationEndPoint + OptimoveUserDefaults.shared.tenantToken! + "/"
            + OptimoveUserDefaults.shared.version! + ".json"
    }

    private func reportSdkVersion() {
        let configUrl = getFullConfigurationPath()
        let event = SdkVersionEvent(configUrl: configUrl)
        if let config = Optimove.shared.eventWarehouse?.getConfig(ofEvent: event) {
            OptiLoggerMessages.logOptitrackReport(event: "sdk metadata")
            let dec = OptimoveEventDecorator(event: event, config: config)
            report(event: dec, withConfigs: config)
        } else {
            OptiLoggerMessages.logLoadingConfigsError(ofEvent: "sdk metadata")
        }
    }

    private func reportAppOpenedIfNeeded() {
        if UIApplication.shared.applicationState != .background {
            self.reportAppOpen()
        }
    }

    private func isOptInOutStateChanged(with newState: Bool) -> Bool {
        return newState != OptimoveUserDefaults.shared.isOptiTrackOptIn
    }

    private func reportOptInOutIfNeeded() {
        deviceStateMonitor.getStatus(of: .userNotification) { (granted) in
            if self.isOptInOutStateChanged(with: granted) {
                if granted {
                    let event = OptipushOptIn()
                    guard let config = Optimove.shared.eventWarehouse?.getConfig(ofEvent: event) else {
                        OptiLoggerMessages.logLoadingConfigsError(ofEvent: "opt in")
                        return
                    }
                    OptiLoggerMessages.logOptitrackReport(event: "opt in")
                    let dec = OptimoveEventDecorator(event: event, config: config)
                    self.report(event: dec, withConfigs: config)
                    OptimoveUserDefaults.shared.isOptiTrackOptIn = true
                } else {
                    let event = OptipushOptOut()
                    guard let config = Optimove.shared.eventWarehouse?.getConfig(ofEvent: event) else {
                        OptiLoggerMessages.logLoadingConfigsError(ofEvent: "opt out")
                        return
                    }
                    OptiLoggerMessages.logOptitrackReport(event: "opt out")
                    let dec = OptimoveEventDecorator(event: event, config: config)
                    self.report(event: dec, withConfigs: config)
                    OptimoveUserDefaults.shared.isOptiTrackOptIn = false
                }
            }
        }
    }

    private func trackAppOpened() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { (_) in
            if Date().timeIntervalSince1970 - self.openApplicationTime > 1800 {
                self.reportAppOpen()
            }
        }
    }

    private func isNeedToReportSetUserId() -> Bool {
        return OptimoveUserDefaults.shared.isSetUserIdSucceed == false && OptimoveUserDefaults.shared.customerID != nil
    }
}

extension OptiTrack {
    private func reportPendingEvents() {
        if RunningFlagsIndication.isComponentRunning(.optiTrack) {
            if let jsonEvents = OptimoveFileManager.load(file: "pendingOptimoveEvents.json", isInSharedContainer: false)
            {
                let decoder = JSONDecoder()
                let events = try! decoder.decode([Event].self, from: jsonEvents)

                //Since all stored events are already matomo events type, no need to do the entire process
                events.forEach { (event) in
                    DispatchQueue.main.async {
                        self.tracker.track(event)
                    }
                }
            }
        }
    }

    private func reportAppOpen() {
        let event = AppOpenEvent()
        guard let config = Optimove.shared.eventWarehouse?.getConfig(ofEvent: event) else {
            OptiLoggerMessages.logLoadingConfigsError(ofEvent: "app open")
            return
        }
        OptiLoggerMessages.logOptitrackReport(event: "app open")
        let dec = OptimoveEventDecorator(event: event, config: config)
        report(event: dec, withConfigs: config)
        openApplicationTime = Date().timeIntervalSince1970
    }
}
