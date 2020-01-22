//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import OptimoveCore
@testable import OptimoveSDK

let defaultTimeout: TimeInterval = 0.8

// This special timeout was added to solve an failed tests since the realtime timeout was increased.
// Should be a temporary solution related to a backed issue.
let realtimeTimeout: TimeInterval = defaultTimeout + 1

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

    func prefillStorageWithDefaultValues() {
        storage.installationID = UUID().uuidString
        storage.siteID = StubConstants.tenantID
    }

    func prefillStorageAsVisitor() {
        prefillStorageWithDefaultValues()
        storage.initialVisitorId = StubConstants.initialVisitorId
        storage.visitorID = StubConstants.visitorID
    }

    func prefillStorageAsCustomer() {
        prefillStorageWithDefaultValues()
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
