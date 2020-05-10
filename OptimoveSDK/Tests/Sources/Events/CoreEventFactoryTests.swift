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

    func test_create_AppOpenEvent() throws {
        prefillStorageAsVisitor()
        let expectation = XCTestExpectation(description: "Event creation failed for \(#function)")
        let event = try self.factory.createEvent(.appOpen)
        XCTAssert(event.name == AppOpenEvent.Constants.name)
        expectation.fulfill()
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_create_SetUserIdEvent() throws {
        prefillStorageAsCustomer()
        let expectation = XCTestExpectation(description: "Event creation failed for \(#function)")
        let event = try self.factory.createEvent(.setUserId)
        XCTAssert(event.name == SetUserIdEvent.Constants.name)
        expectation.fulfill()
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_create_metaData() throws {
        prefillStorageAsVisitor()
        storage.configurationEndPoint = URL(string: "https://optimove.net")
        storage.tenantToken = "1234"
        storage.version = "1"
        let expectation = XCTestExpectation(description: "Event creation failed for \(#function)")
        let event = try self.factory.createEvent(.metaData)
        XCTAssert(event.name == MetaDataEvent.Constants.name)
        expectation.fulfill()
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_create_optipushOptIn() throws {
        prefillStorageAsVisitor()
        let expectation = XCTestExpectation(description: "Event creation failed for \(#function)")
        let event = try self.factory.createEvent(.optipushOptIn)
        XCTAssert(event.name == OptEvent.Constants.optInName)
        expectation.fulfill()
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_create_optipushOptOut() throws {
        prefillStorageAsVisitor()
        let expectation = XCTestExpectation(description: "Event creation failed for \(#function)")
        let event = try self.factory.createEvent(.optipushOptOut)
        XCTAssert(event.name == OptEvent.Constants.optOutName)
        expectation.fulfill()
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_create_setAdvertisingId() throws {
        prefillStorageAsVisitor()
        let expectation = XCTestExpectation(description: "Event creation failed for \(#function)")
        let event = try self.factory.createEvent(.setAdvertisingId)
        XCTAssert(event.name == SetAdvertisingIdEvent.Constants.name)
        expectation.fulfill()
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_create_setUserAgent() throws {
        prefillStorageAsVisitor()
        let expectation = XCTestExpectation(description: "Event creation failed for \(#function)")
        let event = try self.factory.createEvent(.setUserAgent)
        XCTAssert(event.name == SetUserAgent.Constants.name)
        expectation.fulfill()
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_create_pageVisit() throws {
        let expectation = XCTestExpectation(description: "Event creation failed for \(#function)")
        let event = try self.factory.createEvent(.pageVisit(title: "", category: ""))
        XCTAssert(event.name == PageVisitEvent.Constants.name)
        expectation.fulfill()
        wait(for: [expectation], timeout: defaultTimeout)
    }

}
