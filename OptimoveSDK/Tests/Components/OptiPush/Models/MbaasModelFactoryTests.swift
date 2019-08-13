// Copiright 2019 Optimove

import XCTest
@testable import OptimoveSDK

class MbaasModelFactoryTests: OptimoveTestCase {

    var factory: MbaasModelFactory!

    override func setUp() {
        super.setUp()
        factory = MbaasModelFactory(
            storage: storage,
            processInfo: ProcessInfo(),
            device: Device.self,
            bundle: Bundle.self
        )
    }

    func test_create_registration_for_visitor() {
        // given
        let operation: MbaasOperation = .registration
        let expectedAppNs = (try! Bundle.getApplicationNameSpace()).setAsMongoKey()

        // and
        prefillStorageAsVisitor()

        // when
        XCTAssertNoThrow(try factory.createModel(for: operation))
        let model = try! factory.createModel(for: operation) as! RegistartionMbaasModel

        // then
        XCTAssert(model.isMbaasOptIn == StubConstants.isMbaasOptIn)
        XCTAssert(model.tenantId == StubConstants.tenantID)
        XCTAssert(model.fcmToken == StubConstants.fcmToken)
        XCTAssert(model.osVersion == ProcessInfo().operatingSystemVersionOnlyString)
        XCTAssert(model.userIdPayload == BaseMbaasModel.UserIdPayload.visitorID(StubConstants.visitorID))
        XCTAssert(model.operation == operation)
        XCTAssert(model.appNs == expectedAppNs)
        XCTAssert(model.deviceId == Device.uuid)
    }

    func test_create_registration_for_customer() {
        // given
        let operation: MbaasOperation = .registration
        let expectedAppNs = (try! Bundle.getApplicationNameSpace()).setAsMongoKey()

        // and
        prefillStorageAsCustomer()

        // when
        XCTAssertNoThrow(try factory.createModel(for: operation))
        let model = try! factory.createModel(for: operation) as! RegistartionMbaasModel

        // then
        XCTAssert(model.isMbaasOptIn == StubConstants.isMbaasOptIn)
        XCTAssert(model.tenantId == StubConstants.tenantID)
        XCTAssert(model.fcmToken == StubConstants.fcmToken)
        XCTAssert(model.osVersion == ProcessInfo().operatingSystemVersionOnlyString)
        XCTAssert(model.userIdPayload == BaseMbaasModel.UserIdPayload.customerID(
            BaseMbaasModel.UserIdPayload.CustomerIdPayload(
                customerID: StubConstants.customerID,
                isConversion: StubConstants.isFirstConversion,
                initialVisitorId: StubConstants.initialVisitorId)
            )
        )
        XCTAssert(model.operation == operation)
        XCTAssert(model.appNs == expectedAppNs)
        XCTAssert(model.deviceId == Device.uuid)
    }

    func test_create_unregistration_for_visitor() {
        runDefaultModelAsVisitor(operation: .unregistration)
    }

    func test_create_unregistration_for_customer() {
        runDefaultModelAsCustomer(operation: .unregistration)
    }

    func test_create_optIn_for_visitor() {
        runDefaultModelAsVisitor(operation: .optIn)
    }

    func test_create_optIn_for_customer() {
        runDefaultModelAsCustomer(operation: .optIn)
    }

    func test_create_optOut_for_visitor() {
        runDefaultModelAsVisitor(operation: .optOut)
    }

    func test_create_optOut_for_customer() {
        runDefaultModelAsCustomer(operation: .optOut)
    }

    private func runDefaultModelAsCustomer(operation: MbaasOperation) {
        // and
        prefillStorageAsCustomer()
        let expectedAppNs = (try! Bundle.getApplicationNameSpace()).setAsMongoKey()

        // when
        XCTAssertNoThrow(try factory.createModel(for: operation))
        let model = try! factory.createModel(for: operation) as! MbaasModel

        // then
        XCTAssert(model.tenantId == StubConstants.tenantID)
        XCTAssert(model.userIdPayload == BaseMbaasModel.UserIdPayload.customerID(
            BaseMbaasModel.UserIdPayload.CustomerIdPayload(
                customerID: StubConstants.customerID,
                isConversion: StubConstants.isFirstConversion,
                initialVisitorId: StubConstants.initialVisitorId)
            )
        )
        XCTAssert(model.operation == operation)
        XCTAssert(model.appNs == expectedAppNs)
        XCTAssert(model.deviceId == Device.uuid)
    }

    private func runDefaultModelAsVisitor(operation: MbaasOperation) {
        // and
        prefillStorageAsVisitor()
        let expectedAppNs = (try! Bundle.getApplicationNameSpace()).setAsMongoKey()

        // when
        XCTAssertNoThrow(try factory.createModel(for: operation))
        let model = try! factory.createModel(for: operation) as! MbaasModel

        // then
        XCTAssert(model.tenantId == StubConstants.tenantID)
        XCTAssert(model.userIdPayload == BaseMbaasModel.UserIdPayload.visitorID(StubConstants.visitorID))
        XCTAssert(model.operation == operation)
        XCTAssert(model.appNs == expectedAppNs)
        XCTAssert(model.deviceId == Device.uuid)
    }

}
