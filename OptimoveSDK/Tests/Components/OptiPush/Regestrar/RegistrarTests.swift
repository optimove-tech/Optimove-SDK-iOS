// Copiright 2019 Optimove

import XCTest
@testable import OptimoveSDK

class RegistrarTests: OptimoveTestCase {

    var registrable: Registrable!
    var networking: MockRegistrarNetworking!
    var modelFactory: MbaasModelFactory!
    var backup: MockMbaasBackup!

    override func setUp() {
        super.setUp()
        networking = MockRegistrarNetworking()
        modelFactory = MbaasModelFactory(
            storage: storage,
            processInfo: ProcessInfo(),
            device: Device.self,
            bundle: Bundle.self
        )
        backup = MockMbaasBackup()
        registrable = Registrar(
            storage: storage,
            modelFactory: modelFactory,
            networking: networking,
            backup: backup
        )
    }

    func test_register() {
        // given
        prefillStorageAsVisitor()

        // then
        let networkExpectation = expectation(description: "Request was not generated.")
        networking.assertFunction = { (model) in
            XCTAssert(model.operation == .registration)
            networkExpectation.fulfill()
            return .success("")
        }

        // and
        let successFlagExpectation = expectation(description: "Success flag was not updated.")
        storage.assertFunction = { (value: Any?, key: StorageKey) -> Void in
            if key == .registrationSuccess {
                XCTAssert(value as? Bool == true)
                successFlagExpectation.fulfill()
            }
        }

        // and
        let backupExpectation = expectation(description: "backup was not updated.")
        backup.clearLastAssert = { operation in
            XCTAssert(operation == .registration)
            backupExpectation.fulfill()
        }

        // when
        registrable.register()

        wait(for: [networkExpectation, successFlagExpectation, backupExpectation], timeout: expectationTimeout)
    }

    func test_unregister() {
        // given
        prefillStorageAsCustomer()

        // then
        let networkExpectation = expectation(description: "Request was not generated.")
        networking.assertFunction = { (model) in
            XCTAssert(model.operation == .unregistration)
            networkExpectation.fulfill()
            return .success("")
        }

        // and
        let successFlagExpectation = expectation(description: "Success flag was not updated.")
        storage.assertFunction = { (value: Any?, key: StorageKey) -> Void in
            if key == .unregistrationSuccess {
                XCTAssert(value as? Bool == true)
                successFlagExpectation.fulfill()
            }
        }

        // and
        let backupExpectation = expectation(description: "backup was not updated.")
        backup.clearLastAssert = { operation in
            XCTAssert(operation == .unregistration)
            backupExpectation.fulfill()
        }


        // when
        let callbackExpectation = expectation(description: "Callback was not generated.")
        registrable.unregister {
            callbackExpectation.fulfill()
        }
        wait(for: [networkExpectation,
                   callbackExpectation,
                   successFlagExpectation,
                   backupExpectation], timeout: expectationTimeout)
    }

    func test_optIn() {
        // given
        prefillStorageAsVisitor()

        // then
        let networkExpectation = expectation(description: "Request was not generated.")
        networking.assertFunction = { (model) in
            XCTAssert(model.operation == .optIn)
            networkExpectation.fulfill()
            return .success("")
        }

        // and
        let optInFlagExpectation = expectation(description: "OptInFlag was not updated.")
        let optSuccessFlagExpectation = expectation(description: "OptSuccess was not updated.")
        storage.assertFunction = { (value: Any?, key: StorageKey) -> Void in
            if key == .isMbaasOptIn {
                XCTAssert(value as? Bool == true)
                optInFlagExpectation.fulfill()
            }
            if key == .optSuccess {
                XCTAssert(value as? Bool == true)
                optSuccessFlagExpectation.fulfill()
            }
        }

        // and
        let backupExpectation = expectation(description: "backup was not updated.")
        backup.clearLastAssert = { operation in
            XCTAssert(operation == .optIn)
            backupExpectation.fulfill()
        }

        // when
        registrable.optIn()
        wait(for: [networkExpectation,
                   optInFlagExpectation,
                   optSuccessFlagExpectation,
                   backupExpectation], timeout: expectationTimeout)
    }

    func test_optOut() {
        // given
        prefillStorageAsVisitor()

        // then
        let networkExpectation = expectation(description: "Request was not generated.")
        networking.assertFunction = { (model) in
            XCTAssert(model.operation == .optOut)
            networkExpectation.fulfill()
            return .success("")
        }

        // and
        let optSuccessFlagExpectation = expectation(description: "OptSuccess was not updated.")
        storage.assertFunction = { (value: Any?, key: StorageKey) -> Void in
            if key == .optSuccess {
                XCTAssert(value as? Bool == true)
                optSuccessFlagExpectation.fulfill()
            }
        }

        // and
        let backupExpectation = expectation(description: "backup was not updated.")
        backup.clearLastAssert = { operation in
            XCTAssert(operation == .optOut)
            backupExpectation.fulfill()
        }

        // when
        registrable.optOut()
        wait(for: [networkExpectation,
                   optSuccessFlagExpectation,
                   backupExpectation], timeout: expectationTimeout)
    }

    func test_retryFailedOperationsIfExist_unregistration_failed() {
        // given
        prefillStorageAsCustomer()

        // and
        storage.isUnregistrationSuccess = false

        // and
        let model = try! modelFactory.createModel(for: .unregistration)
        try! backup.backup(model)

        // then
        let unregesterExpectation = expectation(description: "Unregester request was not generated.")
        let regesterExpectation = expectation(description: "Regester request was not generated.")
        networking.assertFunction = { (model) in
            if model.operation == .unregistration {
                unregesterExpectation.fulfill()
            }
            if model.operation == .registration {
                regesterExpectation.fulfill()
            }
            return .success("")
        }

        // and
        let unregistrationSuccessFlagExpectation = expectation(description: "unregistrationSuccess flag was not updated.")
        let optSuccessFlagExpectation = expectation(description: "optSuccess flag was not updated.")
        storage.assertFunction = { (value: Any?, key: StorageKey) -> Void in
            if key == .unregistrationSuccess {
                XCTAssert(value as? Bool == true)
                unregistrationSuccessFlagExpectation.fulfill()
            }
            if key == .registrationSuccess {
                XCTAssert(value as? Bool == true)
                optSuccessFlagExpectation.fulfill()
            }
        }

        // and
        let backupExpectation = expectation(description: "backup was not updated.")
        backup.clearLastAssert = { operation in
            if operation == .unregistration {
                backupExpectation.fulfill()
            }
        }

        // when
        try! registrable.retryFailedOperationsIfExist()
        wait(for: [regesterExpectation,
                   unregesterExpectation,
                   unregistrationSuccessFlagExpectation,
                   optSuccessFlagExpectation,
                   backupExpectation], timeout: expectationTimeout)
    }

    func test_retryFailedOperationsIfExist_registration_failed() {
        // given
        prefillStorageAsCustomer()

        // and
        storage.isRegistrationSuccess = false

        // and
        let model = try! modelFactory.createModel(for: .registration)
        try! backup.backup(model)

        // then
        let regesterExpectation = expectation(description: "Regester request was not generated.")
        networking.assertFunction = { (model) in
            if model.operation == .registration {
                regesterExpectation.fulfill()
            }
            return .success("")
        }

        // and
        let registrationSuccessFlagExpectation = expectation(description: "optSuccess flag was not updated.")
        storage.assertFunction = { (value: Any?, key: StorageKey) -> Void in
            if key == .registrationSuccess {
                XCTAssert(value as? Bool == true)
                registrationSuccessFlagExpectation.fulfill()
            }
        }

        // and
        let backupExpectation = expectation(description: "backup was not updated.")
        backup.clearLastAssert = { operation in
            XCTAssert(operation == .registration)
            backupExpectation.fulfill()
        }


        // when
        try! registrable.retryFailedOperationsIfExist()
        wait(for: [regesterExpectation,
                   registrationSuccessFlagExpectation,
                   backupExpectation], timeout: expectationTimeout)
    }

    func test_retryFailedOperationsIfExist_isOptRequest_failed() {
        // given
        prefillStorageAsCustomer()

        // and
        storage.isOptRequestSuccess = false

        // and
        let model = try! modelFactory.createModel(for: .optIn)
        try! backup.backup(model)

        // then
        let regesterExpectation = expectation(description: "Regester request was not generated.")
        networking.assertFunction = { (model) in
            if model.operation == .optIn {
                regesterExpectation.fulfill()
            }
            return .success("")
        }

        // and
        let registrationSuccessFlagExpectation = expectation(description: "optSuccess flag was not updated.")
        storage.assertFunction = { (value: Any?, key: StorageKey) -> Void in
            if key == .optSuccess {
                XCTAssert(value as? Bool == true)
                registrationSuccessFlagExpectation.fulfill()
            }
        }

        // and
        let backupExpectation = expectation(description: "backup was not updated.")
        backup.clearLastAssert = { operation in
            XCTAssert(operation == .optIn)
            backupExpectation.fulfill()
        }

        // when
        try! registrable.retryFailedOperationsIfExist()
        wait(for: [regesterExpectation,
                   registrationSuccessFlagExpectation,
                   backupExpectation], timeout: expectationTimeout)
    }

    func test_register_failure() {
        // given
        prefillStorageAsVisitor()

        // then
        let networkExpectation = expectation(description: "Request was not generated.")
        networking.assertFunction = { (model) in
            XCTAssert(model.operation == .registration)
            networkExpectation.fulfill()
            return .failure(StubError.test)
        }

        // and
        let successFlagExpectation = expectation(description: "Success flag was not updated.")
        storage.assertFunction = { (value: Any?, key: StorageKey) -> Void in
            if key == .registrationSuccess {
                XCTAssert(value as? Bool == false)
                successFlagExpectation.fulfill()
            }
        }

        // and
        let backupExpectation = expectation(description: "backup was not updated.")
        backup.backupAssert = { model in
            XCTAssert(model.operation == .registration)
            backupExpectation.fulfill()
        }

        // when
        registrable.register()

        wait(for: [networkExpectation, successFlagExpectation, backupExpectation], timeout: expectationTimeout)
    }
}

enum StubError: Error {
    case test
}

final class MockMbaasBackup: MbaasBackup {

    var state: [MbaasOperation: BaseMbaasModel?] = [:]

    var backupAssert: ((BaseMbaasModel) -> Void)?

    func backup<T: BaseMbaasModel>(_ model: T) throws {
        state[model.operation] = model
        backupAssert?(model)
    }

    var clearLastAssert: ((MbaasOperation) -> Void)?

    func clearLast(for operation: MbaasOperation) throws {
        state[operation] = nil
        clearLastAssert?(operation)
    }

    var restoreLastAssert: ((MbaasOperation) -> Void)?

    func restoreLast<T: BaseMbaasModel>(for operation: MbaasOperation) throws -> T {
        restoreLastAssert?(operation)
        return try cast(state[operation] as Any?)
    }

}
