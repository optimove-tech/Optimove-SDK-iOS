//  Copyright © 2019 Optimove. All rights reserved.

import OptimoveCore
@testable import OptimoveSDK
import XCTest

public let defaultTimeout: TimeInterval = 0.8

open class OptimoveTestCase: XCTestCase {
    public var storage = MockOptimoveStorage()

    public enum StubConstants {
        public static let fcmToken = "fcmToken"
        public static let isMbaasOptIn = false
        public static let tenantID = 100
        public static let visitorID = StubVariables.visitorID
        public static let customerID = StubVariables.customerID
        public static let initialVisitorId = StubVariables.initialVisitorId
        public static let apnsToken = Data()
    }

    public func prefillStorageWithConfiguration() {
        storage.siteID = StubConstants.tenantID
        storage.tenantID = StubConstants.tenantID
        storage.optitrackEndpoint = URL(string: "https://optimove.net")!
    }

    public func prefillStorageWithTheFirstLaunch() {
        prefillStorageWithConfiguration()
        storage.installationID = UUID().uuidString
        storage.userAgent = "user-agent"
        storage.firstRunTimestamp = Date().timeIntervalSince1970.seconds
    }

    public func prefillStorageAsVisitor() {
        prefillStorageWithTheFirstLaunch()
        storage.initialVisitorId = StubConstants.initialVisitorId
        storage.visitorID = StubConstants.visitorID
    }

    public func prefillStorageAsCustomer() {
        prefillStorageAsVisitor()
        storage.customerID = StubConstants.customerID
        storage.initialVisitorId = StubConstants.initialVisitorId
    }
}

extension String {
    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< length).map { _ in letters.randomElement()! })
    }
}

enum StubError: Error {
    case test
}
