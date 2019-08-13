// Copiright 2019 Optimove

import XCTest
@testable import OptimoveSDK

let expectationTimeout: TimeInterval = 1

class OptimoveTestCase: XCTestCase {

    var storage: MockOptimoveStorage!

    override func setUp() {
        storage = MockOptimoveStorage()
    }

    struct StubConstants {
        static let fcmToken = "fcmToken"
        static let isMbaasOptIn = false
        static let tenantID = 100
        static let visitorID = StubVariables.visitorID
        static let customerID = StubVariables.customerID
        static let isFirstConversion = false
        static let initialVisitorId = StubVariables.initialVisitorId
    }

    func defaultStorage() {
        storage.fcmToken = StubConstants.fcmToken
        storage.siteID = StubConstants.tenantID
        storage.isMbaasOptIn = StubConstants.isMbaasOptIn
    }

    func prefillStorageAsCustomer() {
        storage.customerID = StubConstants.customerID
        storage.isFirstConversion = StubConstants.isFirstConversion
        storage.initialVisitorId = StubConstants.initialVisitorId
        defaultStorage()
    }

    func prefillStorageAsVisitor() {
        storage.visitorID = StubConstants.visitorID
        defaultStorage()
    }

}
