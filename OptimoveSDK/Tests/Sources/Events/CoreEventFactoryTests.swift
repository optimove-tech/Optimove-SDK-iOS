//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import OptimoveCore
@testable import OptimoveSDK

class CoreEventFactoryTests: XCTestCase {

    var storage: OptimoveStorage!
    var factory: CoreEventFactory!
    var dateProvider: MockDateTimeProvider!

    override func setUp() {
        storage = MockOptimoveStorage()
        dateProvider = MockDateTimeProvider()
        factory = CoreEventFactoryImpl(
            storage: storage,
            dateTimeProvider: dateProvider
        )
    }

    func test_create_AppOpenEvent() {
        XCTAssertNoThrow({
            // when
            let event = try self.factory.createEvent(.appOpen)

            // then
            XCTAssert(event.name == AppOpenEvent.Constants.name)
        })
    }

    func test_create_SetUserIdEvent() {
        XCTAssertNoThrow({
            // when
            let event = try self.factory.createEvent(.setUserId)

            // then
            XCTAssert(event.name == SetUserIdEvent.Constants.name)
        })
    }

    func test_create_metaData() {
        XCTAssertNoThrow({
            // when
            let event = try self.factory.createEvent(.metaData)

            // then
            XCTAssert(event.name == SetUserIdEvent.Constants.name)
        })
    }

    func test_create_optipushOptIn() {
        XCTAssertNoThrow({
            // when
            let event = try self.factory.createEvent(.optipushOptIn)

            // then
            XCTAssert(event.name == SetUserIdEvent.Constants.name)
        })
    }

    func test_create_optipushOptOut() {
        XCTAssertNoThrow({
            // when
            let event = try self.factory.createEvent(.optipushOptOut)

            // then
            XCTAssert(event.name == SetUserIdEvent.Constants.name)
        })
    }

    func test_create_setAdvertisingId() {
        XCTAssertNoThrow({
            // when
            let event = try self.factory.createEvent(.setAdvertisingId)

            // then
            XCTAssert(event.name == SetUserIdEvent.Constants.name)
        })
    }

    func test_create_setUserAgent() {
        XCTAssertNoThrow({
            // when
            let event = try self.factory.createEvent(.setUserAgent)

            // then
            XCTAssert(event.name == SetUserIdEvent.Constants.name)
        })
    }

    func test_create_pageVisit() {
        XCTAssertNoThrow({
            // when
            let event = try self.factory.createEvent(.pageVisit(screenPath: "", screenTitle: "", category: ""))

            // then
            XCTAssert(event.name == SetUserIdEvent.Constants.name)
        })
    }

}
