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
    case pageVisit(screenPath: String, screenTitle: String, category: String?)
    case ping
}

protocol CoreEventFactory {
    func createEvent(_ type: CoreEventType) throws -> OptimoveCoreEvent
}

import AdSupport

final class CoreEventFactoryImpl {

    private var storage: OptimoveStorage
    private let deviceId: String = SDKDevice.uuid
    private let dateTimeProvider: DateTimeProvider
    private var timestamp: TimeInterval {
        return dateTimeProvider.now.timeIntervalSince1970
    }

    init(storage: OptimoveStorage,
         dateTimeProvider: DateTimeProvider) {
        self.storage = storage
        self.dateTimeProvider = dateTimeProvider
    }

}

extension CoreEventFactoryImpl: CoreEventFactory {

    func createEvent(_ type: CoreEventType) throws -> OptimoveCoreEvent {
        switch type {
        case .appOpen:
            return try createAppOpenEvent()
        case .setUserId:
            return try createSetUserIdEvent()
        case .optipushOptIn:
            return try createOptipushOptInEvent()
        case .optipushOptOut:
            return try createOptipushOptOutEvent()
        case .metaData:
            return try createMetaDataEvent()
        case let .pageVisit(screenPath: sp, screenTitle: st, category: c):
            return createPageVisitEvent(screenPath: sp, screenTitle: st, category: c)
        case .ping:
            return try createPingEvent()
        case .setUserAgent:
            return try createSetUserAgentEvent()
        case .setAdvertisingId:
            return try createSetAdvertisingIdEvent()
        case .setUserEmail:
            return try createSetUserEmailEvent()
        }
    }
}

private extension CoreEventFactoryImpl {

    func createAppOpenEvent() throws -> AppOpenEvent {
        return AppOpenEvent(
            bundleIdentifier: try getApplicationNamespace(),
            deviceID: deviceId,
            visitorID: storage.visitorID,
            customerID: storage.customerID
        )
    }

    func createOptipushOptInEvent() throws -> OptipushOptInEvent {
        return OptipushOptInEvent(
            timestamp: timestamp,
            applicationNameSpace: try getApplicationNamespace(),
            deviceId: deviceId
        )
    }

    func createOptipushOptOutEvent() throws -> OptipushOptOutEvent {
        return OptipushOptOutEvent(
            timestamp: timestamp,
            applicationNameSpace: try getApplicationNamespace(),
            deviceId: deviceId
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
        return MetaDataEvent(
            configUrl: configUrl,
            sdkVersion: sdkVersion,
            bundleIdentifier: tenantBundle
        )
    }

    func createSetUserAgentEvent() throws -> SetUserAgent {
        return SetUserAgent(
            userAgent: try storage.getUserAgent()
        )
    }

    func createSetAdvertisingIdEvent() throws -> SetAdvertisingIdEvent {
        return SetAdvertisingIdEvent(
            advertisingId: getAdvertisingIdentifier(),
            deviceId: deviceId,
            appNs: try getApplicationNamespace()
        )
    }

    func createPageVisitEvent(screenPath: String, screenTitle: String, category: String?) -> PageVisitEvent {
        return PageVisitEvent(
            customURL: screenPath,
            pageTitle: screenTitle,
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

    func createPingEvent() throws -> PingEvent {
        return PingEvent(
            visitorId: try storage.getVisitorID(),
            deviceId: deviceId,
            appNs: try getApplicationNamespace()
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
            let newAdvertisingIdentifier =  UUID().uuidString
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
