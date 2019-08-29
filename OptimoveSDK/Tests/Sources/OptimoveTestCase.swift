//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK


let defaultTimeout: TimeInterval = 1
// This special timeout was added to solve an failed tests since the realtime timeout was increased.
// Should be a temporary solution related to a backed issue.
let timeoutForRealtime: TimeInterval = 2

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

extension String {

    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }

}
