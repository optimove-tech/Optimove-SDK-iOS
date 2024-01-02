//  Copyright © 2019 Optimove. All rights reserved.

import OptimoveCore
@testable import OptimoveSDK
@testable import OptimoveTest
import XCTest

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
        let event = try factory.createEvent(.appOpen)
        XCTAssert(event.name == AppOpenEvent.Constants.name)
        expectation.fulfill()
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_create_SetUserIdEvent() throws {
        prefillStorageAsVisitor()
        let expectation = XCTestExpectation(description: "Event creation failed for \(#function)")
        let user = User(userID: StubConstants.customerID)
        let event = try factory.createEvent(.setUser(user: user))
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
        let event = try factory.createEvent(.metaData)
        XCTAssert(event.name == MetaDataEvent.Constants.name)
        expectation.fulfill()
        wait(for: [expectation], timeout: defaultTimeout)
    }

    func test_create_pageVisit() throws {
        let expectation = XCTestExpectation(description: "Event creation failed for \(#function)")
        let event = try factory.createEvent(.pageVisit(title: "", category: ""))
        XCTAssert(event.name == PageVisitEvent.Constants.name)
        expectation.fulfill()
        wait(for: [expectation], timeout: defaultTimeout)
    }
}
