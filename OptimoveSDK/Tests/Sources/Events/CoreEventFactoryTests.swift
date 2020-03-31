//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import OptimoveCore
@testable import OptimoveSDK

class CoreEventFactoryTests: OptimoveTestCase {

    var factory: CoreEventFactory!
    var dateProvider: MockDateTimeProvider!

    override func setUp() {
        dateProvider = MockDateTimeProvider()
        factory = CoreEventFactoryImpl(
            storage: storage,
            dateTimeProvider: dateProvider,
            locationService: MockLocationService()
        )
    }

    func test_create_AppOpenEvent() {
        prefillStorageAsVisitor()
        let expectation = XCTestExpectation(description: "Event creation failed for \(#function)")
        try? self.factory.createEvent(.appOpen) { event in
            XCTAssert(event.name == AppOpenEvent.Constants.name)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_create_SetUserIdEvent() {
        prefillStorageAsCustomer()
        let expectation = XCTestExpectation(description: "Event creation failed for \(#function)")
        try? self.factory.createEvent(.setUserId) { event in
            XCTAssert(event.name == SetUserIdEvent.Constants.name)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_create_metaData() {
        prefillStorageAsVisitor()
        storage.configurationEndPoint = URL(string: "https://optimove.net")
        storage.tenantToken = "1234"
        storage.version = "1"
        let expectation = XCTestExpectation(description: "Event creation failed for \(#function)")
        try? self.factory.createEvent(.metaData) { event in
            XCTAssert(event.name == MetaDataEvent.Constants.name)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_create_optipushOptIn() {
        prefillStorageAsVisitor()
        let expectation = XCTestExpectation(description: "Event creation failed for \(#function)")
        try? self.factory.createEvent(.optipushOptIn) { event in
            XCTAssert(event.name == OptEvent.Constants.optInName)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_create_optipushOptOut() {
        prefillStorageAsVisitor()
        let expectation = XCTestExpectation(description: "Event creation failed for \(#function)")
        try? self.factory.createEvent(.optipushOptOut) { event in
            XCTAssert(event.name == OptEvent.Constants.optOutName)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_create_setAdvertisingId() {
        prefillStorageAsVisitor()
        let expectation = XCTestExpectation(description: "Event creation failed for \(#function)")
        try? self.factory.createEvent(.setAdvertisingId) { event in
            XCTAssert(event.name == SetAdvertisingIdEvent.Constants.name)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_create_setUserAgent() {
        prefillStorageAsVisitor()
        let expectation = XCTestExpectation(description: "Event creation failed for \(#function)")
        try? self.factory.createEvent(.setUserAgent) { event in
            XCTAssert(event.name == SetUserAgent.Constants.name)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_create_pageVisit() {
        let expectation = XCTestExpectation(description: "Event creation failed for \(#function)")
        try? self.factory.createEvent(.pageVisit(title: "", category: "")) { event in
            XCTAssert(event.name == PageVisitEvent.Constants.name)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: defaultTimeout)
    }

}
