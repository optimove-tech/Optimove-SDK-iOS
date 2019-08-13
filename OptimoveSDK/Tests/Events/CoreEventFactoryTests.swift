// Copiright 2019 Optimove

import XCTest
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

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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

    // TODO: Cover all lefts.

}
