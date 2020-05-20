//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import OptimoveCore

let defaultTimeout: TimeInterval = 0.8

class OptimoveTestCase: XCTestCase {

    var storage = MockOptimoveStorage()

    struct StubConstants {
        static let fcmToken = "fcmToken"
        static let isMbaasOptIn = false
        static let tenantID = 100
        static let visitorID = StubVariables.visitorID
        static let customerID = StubVariables.customerID
        static let initialVisitorId = StubVariables.initialVisitorId
        static let apnsToken = Data()
    }

    func prefillStorageWithConfiguration() {
        storage.siteID = StubConstants.tenantID
    }

    func prefillStorageWithTheFirstLaunch() {
        prefillStorageWithConfiguration()
        storage.installationID = UUID().uuidString
        storage.userAgent = "user-agent"
        storage.firstVisitTimestamp = Date().timeIntervalSince1970.seconds
    }

    func prefillStorageAsVisitor() {
        prefillStorageWithTheFirstLaunch()
        storage.initialVisitorId = StubConstants.initialVisitorId
        storage.visitorID = StubConstants.visitorID
    }

    func prefillStorageAsCustomer() {
        prefillStorageWithTheFirstLaunch()
        prefillStorageAsVisitor()
        storage.customerID = StubConstants.customerID
        storage.initialVisitorId = StubConstants.initialVisitorId
    }

    func prefillPushToken() {
        storage.apnsToken = StubConstants.apnsToken
    }

}

extension String {

    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }

}

enum StubError: Error {
    case test
}
