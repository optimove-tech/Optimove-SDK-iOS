//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

enum CoreEventType {
    case appOpen
    case optipushOptIn
    case optipushOptOut
    case metaData
    case setUserAgent
    case setUserEmail
    case setAdvertisingId
    case setUserId
    case pageVisit(title: String, category: String?)
}

protocol CoreEventFactory {
    func createEvent(_ type: CoreEventType, _ onComplete: @escaping (OptimoveCoreEvent) -> Void ) throws
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

    func createEvent(_ type: CoreEventType, _ onComplete: @escaping (OptimoveCoreEvent) -> Void ) throws {
        switch type {
        case .appOpen:
            onComplete(try createAppOpenEvent())
        case .setUserId:
            onComplete(try createSetUserIdEvent())
        case .optipushOptIn:
            onComplete(try createOptipushOptInEvent())
        case .optipushOptOut:
            onComplete(try createOptipushOptOutEvent())
        case .metaData:
            try createMetaDataEvent(onComplete: { (result) in
                onComplete(result)
            })
        case let .pageVisit(title: t, category: c):
            onComplete(self.createPageVisitEvent(title: t, category: c))
        case .setUserAgent:
            onComplete(try createSetUserAgentEvent())
        case .setAdvertisingId:
            onComplete(try createSetAdvertisingIdEvent())
        case .setUserEmail:
            onComplete(try createSetUserEmailEvent())
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

    func createMetaDataEvent(onComplete: @escaping (MetaDataEvent) -> Void) throws {
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
        locationService.getLocation(onComplete: { (result) in
            let location = try? result.get()
            let event = MetaDataEvent(
                configUrl: configUrl,
                sdkVersion: sdkVersion,
                bundleIdentifier: tenantBundle,
                location: location?[.locality],
                locationLatitude: location?[.latitude],
                locationLongitude: location?[.longitude],
                language: Locale.preferredLanguages.first
            )
            onComplete(event)
        })
    }

    func createSetUserAgentEvent() throws -> SetUserAgent {
        return SetUserAgent(
            userAgent: try storage.getUserAgent()
        )
    }

    func createSetAdvertisingIdEvent() throws -> SetAdvertisingIdEvent {
        return SetAdvertisingIdEvent(
            advertisingId: getAdvertisingIdentifier(),
            deviceId: try storage.getInstallationID(),
            appNs: try getApplicationNamespace()
        )
    }

    func createPageVisitEvent(title: String, category: String?) -> PageVisitEvent {
        return PageVisitEvent(
            title: title,
            category: category
        )
    }

    func createSetUserIdEvent() throws -> SetUserIdEvent {
        return SetUserIdEvent(
            originalVistorId: try storage.getInitialVisitorId(),
            userId: try storage.getCustomerID(),
            updateVisitorId: try storage.getVisitorID()
        )
    }

    func createSetUserEmailEvent() throws -> SetUserEmailEvent {
        return SetUserEmailEvent(
            email: try storage.getUserEmail()
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
