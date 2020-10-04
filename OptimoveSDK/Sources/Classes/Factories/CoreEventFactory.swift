//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

enum CoreEventType {
    case appOpen
    case optipushOptIn
    case optipushOptOut
    case metaData
    case setUserAgent
    case setUserEmail(email: String)
    case setUserId(userId: String)
    case pageVisit(title: String, category: String?)
}

protocol CoreEventFactory {
    func createEvent(_ type: CoreEventType) throws -> Event
}

import AdSupport

final class CoreEventFactoryImpl {

    private var storage: OptimoveStorage
    private let dateTimeProvider: DateTimeProvider
    private let locationService: LocationService
    private var timestamp: TimeInterval {
        return dateTimeProvider.now.timeIntervalSince1970
    }

    init(storage: OptimoveStorage,
         dateTimeProvider: DateTimeProvider,
         locationService: LocationService) {
        self.storage = storage
        self.dateTimeProvider = dateTimeProvider
        self.locationService = locationService
    }

}

extension CoreEventFactoryImpl: CoreEventFactory {

    func createEvent(_ type: CoreEventType) throws -> Event {
        switch type {
        case .appOpen:
            return try createAppOpenEvent()
        case let .setUserId(userId):
            return try createSetUserIdEvent(userId: userId)
        case .optipushOptIn:
            return try createOptipushOptInEvent()
        case .optipushOptOut:
            return try createOptipushOptOutEvent()
        case .metaData:
            return try createMetaDataEvent()
        case let .pageVisit(title: t, category: c):
            return self.createPageVisitEvent(title: t, category: c)
        case .setUserAgent:
            return try createSetUserAgentEvent()
        case let .setUserEmail(email):
            return try createSetUserEmailEvent(email: email)
        }
    }
}

private extension CoreEventFactoryImpl {

    func createAppOpenEvent() throws -> AppOpenEvent {
        return AppOpenEvent(
            bundleIdentifier: try getApplicationNamespace(),
            deviceID: try storage.getInstallationID(),
            visitorID: storage.visitorID,
            customerID: storage.customerID
        )
    }

    func createOptipushOptInEvent() throws -> OptipushOptInEvent {
        return OptipushOptInEvent(
            timestamp: timestamp,
            applicationNameSpace: try getApplicationNamespace(),
            deviceId: try storage.getInstallationID()
        )
    }

    func createOptipushOptOutEvent() throws -> OptipushOptOutEvent {
        return OptipushOptOutEvent(
            timestamp: timestamp,
            applicationNameSpace: try getApplicationNamespace(),
            deviceId: try storage.getInstallationID()
        )
    }

    func createMetaDataEvent() throws -> MetaDataEvent {
        func getFullConfigurationPath() throws -> String {
            let configurationEndPoint = try storage.getConfigurationEndPoint()
            let tenantToken = try storage.getTenantToken()
            let version = try storage.getVersion()
            return configurationEndPoint
                .appendingPathComponent(tenantToken)
                .appendingPathComponent(version)
                .appendingPathExtension("json")
                .absoluteString
        }
        let configUrl = try getFullConfigurationPath()
        let tenantBundle = try getApplicationNamespace()
        let sdkVersion = getSdkVersion()
        var event: MetaDataEvent?
        let semaphore = DispatchSemaphore(value: 0)
        locationService.getLocation(onComplete: { (result) in
            let location = try? result.get()
            event = MetaDataEvent(
                configUrl: configUrl,
                sdkVersion: sdkVersion,
                bundleIdentifier: tenantBundle,
                location: location?[.locality],
                locationLatitude: location?[.latitude],
                locationLongitude: location?[.longitude],
                language: Locale.preferredLanguages.first
            )
            semaphore.signal()
        })
        _ = semaphore.wait(timeout: .now() + .seconds(3))
        return try unwrap(event)
    }

    func createSetUserAgentEvent() throws -> SetUserAgent {
        return SetUserAgent(
            userAgent: try storage.getUserAgent()
        )
    }

    func createPageVisitEvent(title: String, category: String?) -> PageVisitEvent {
        return PageVisitEvent(
            title: title,
            category: category
        )
    }

    func createSetUserIdEvent(userId: String) throws -> SetUserIdEvent {
        return SetUserIdEvent(
            originalVistorId: try storage.getInitialVisitorId(),
            userId: userId,
            updateVisitorId: try storage.getVisitorID()
        )
    }

    func createSetUserEmailEvent(email: String) throws -> SetUserEmailEvent {
        return SetUserEmailEvent(
            email: email
        )
    }

}

private extension CoreEventFactoryImpl {

    func getApplicationNamespace() throws -> String {
        return try Bundle.getApplicationNameSpace()
    }

    func getSdkVersion() -> String {
        return SDKVersion
    }

    func getAdvertisingIdentifier() -> String {
        if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
            return ASIdentifierManager.shared().advertisingIdentifier.uuidString
        }
        if let storedAdvertisingIdentifier = storage.advertisingIdentifier {
            return storedAdvertisingIdentifier
        } else {
            let newAdvertisingIdentifier = UUID().uuidString
            storage.advertisingIdentifier = newAdvertisingIdentifier
            return newAdvertisingIdentifier
        }
    }

}

enum CoreEventFactoryError: LocalizedError {
    case noCustomerOrVisitorIds

    var errorDescription: String? {
        switch self {
        case .noCustomerOrVisitorIds:
            return """
            Unable to provide value for requred types CustomerID and VisitorID.
            Event types: `AppOpenEvent`
            """
        }
    }
}
