// Copiright 2019 Optimove

import XCTest
@testable import OptimoveSDK

class MbaasBackupTests: XCTestCase {

    var storage: MockOptimoveStorage!
    var backup: MbaasBackupImpl!

    override func setUp() {
        storage = MockOptimoveStorage()
        backup = MbaasBackupImpl(
            storage: storage,
            encoder: JSONEncoder(),
            decoder: JSONDecoder()
        )
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_backup() {
        let operation: MbaasOperation = .optIn
        let model = MbaasModel(
            deviceId: "deviceId",
            appNs: "appNs",
            operation: operation,
            tenantId: 100,
            userIdPayload: BaseMbaasModel.UserIdPayload.visitorID("visitorID")
        )

        // when
        XCTAssertNoThrow(try backup.backup(model))

        // then
        XCTAssert(!storage.storage.isEmpty)
    }

    func test_restore() {
        let operation: MbaasOperation = .optIn
        let model = MbaasModel(
            deviceId: "deviceId",
            appNs: "appNs",
            operation: operation,
            tenantId: 100,
            userIdPayload: BaseMbaasModel.UserIdPayload.visitorID("visitorID")
        )

        // when
        XCTAssertNoThrow(try backup.backup(model))

        // then
        XCTAssert(try backup.restoreLast(for: operation) == model)
    }

    func test_clear() {
        let operation: MbaasOperation = .optIn
        let model = MbaasModel(
            deviceId: "deviceId",
            appNs: "appNs",
            operation: operation,
            tenantId: 100,
            userIdPayload: BaseMbaasModel.UserIdPayload.visitorID("visitorID")
        )
        XCTAssertNoThrow(try backup.backup(model))

        // when
        XCTAssertNoThrow(try backup.clearLast(for: operation))

        // then
        XCTAssert(storage.storage.isEmpty)
    }

}
