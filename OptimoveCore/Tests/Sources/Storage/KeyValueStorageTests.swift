//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveCore

class MockKeyValueStorage: KeyValueStorage {
    var assertFunction: ((_ value: Any?, _ key: StorageKey) -> Void)?
    var state: [StorageKey: Any?] = [:]

    func set(value: Any?, key: StorageKey) {
        state[key] = value
        self.assertFunction?(value, key)
    }

    func value(for key: StorageKey) -> Any? {
        return state[key]
    }

    subscript<T>(key: StorageKey) -> T? {
        get {
            return value(for: key) as? T
        }
        set(newValue) {
            set(value: newValue, key: key)
        }
    }
}

class MockFileStorage: FileStorage {

    var storage: [String: Data] = [:]

    func isExist(fileName: String, shared: Bool) -> Bool {
        return storage[fileName] != nil
    }

    func save<T>(data: T, toFileName: String, shared: Bool) throws where T: Encodable {
        storage[toFileName] = try JSONEncoder().encode(data)
    }

    func saveData(data: Data, toFileName: String, shared: Bool) throws {
        storage[toFileName] = data
    }

    func load(fileName: String, shared: Bool) throws -> Data {
        return try unwrap(storage[fileName])
    }

    func delete(fileName: String, shared: Bool) throws {
        return storage[fileName] = nil
    }

}

class KeyValueStorageTests: XCTestCase {

    var storage: OptimoveStorage!
    let stub_data = Data(capacity: 42)

    override func setUp() {

        storage = StorageFacade(
            groupedStorage: MockKeyValueStorage(),
            sharedStorage: MockKeyValueStorage(),
            fileStorage: MockFileStorage()
        )
    }

    // MARK: Throwable

    func test_customerID() {
        // when
        storage.customerID = StubVariables.string

        // then
        XCTAssertNoThrow(try storage.getCustomerID())
    }

    func test_no_customerID() {
        // when
        storage.customerID = nil

        // then
        XCTAssertThrowsError(try storage.getCustomerID())
    }

    func test_initialVisitorId() {
        // when
        storage.initialVisitorId = StubVariables.string

        // then
        XCTAssertNoThrow(try storage.getInitialVisitorId())
    }

    func test_no_initialVisitorId() {
        // when
        storage.initialVisitorId = nil

        // then
        XCTAssertThrowsError(try storage.getInitialVisitorId())
    }

    func test_tenantToken() {
        // when
        storage.tenantToken = StubVariables.string

        // then
        XCTAssertNoThrow(try storage.getTenantToken())
    }

    func test_no_tenantToken() {
        // when
        storage.tenantToken = nil

        // then
        XCTAssertThrowsError(try storage.getTenantToken())
    }

    func test_visitorID() {
        // when
        storage.visitorID = StubVariables.string

        // then
        XCTAssertNoThrow(try storage.getVisitorID())
    }

    func test_no_visitorID() {
        // when
        storage.visitorID = nil

        // then
        XCTAssertThrowsError(try storage.getVisitorID())
    }

    func test_version() {
        // when
        storage.version = StubVariables.string

        // then
        XCTAssertNoThrow(try storage.getVersion())
    }

    func test_no_version() {
        // when
        storage.version = nil

        // then
        XCTAssertThrowsError(try storage.getVersion())
    }

    func test_userEmail() {
        // when
        storage.userEmail = StubVariables.string

        // then
        XCTAssertNoThrow(try storage.getUserEmail())
    }

    func test_no_userEmail() {
        // when
        storage.userEmail = nil

        // then
        XCTAssertThrowsError(try storage.getUserEmail())
    }

    func test_apnsToken() {
        // when
        storage.apnsToken = stub_data

        // then
        XCTAssertNoThrow(try storage.getApnsToken())
    }

    func test_no_apnsToken() {
        // when
        storage.apnsToken = nil

        // then
        XCTAssertThrowsError(try storage.getApnsToken())
    }

    func test_isMbaasOptIn() {
        // when
        storage.isMbaasOptIn = StubVariables.bool

        // then
        XCTAssertNoThrow(try storage.getIsMbaasOptIn())
    }

    func test_no_isMbaasOptIn() {
        // when
        storage.apnsToken = nil

        // then
        XCTAssertThrowsError(try storage.getIsMbaasOptIn())
    }

    func test_defaultFcmToken() {
        // when
        storage.defaultFcmToken = StubVariables.string

        // then
        XCTAssertNoThrow(try storage.getDefaultFcmToken())
    }

    func test_no_defaultFcmToken() {
        // when
        storage.apnsToken = nil

        // then
        XCTAssertThrowsError(try storage.getDefaultFcmToken())
    }

    func test_fcmToken() {
        // when
        storage.fcmToken = StubVariables.string

        // then
        XCTAssertNoThrow(try storage.getFcmToken())
    }

    func test_no_fcmToken() {
        // when
        storage.apnsToken = nil

        // then
        XCTAssertThrowsError(try storage.getFcmToken())
    }

    func test_firstVisitTimestamp() {
        // when
        storage.firstVisitTimestamp = 42

        // then
        XCTAssertNoThrow(try storage.getFirstVisitTimestamp())
    }

    func test_no_firstVisitTimestamp() {
        // when
        storage.firstVisitTimestamp = nil

        // then
        XCTAssertThrowsError(try storage.getFirstVisitTimestamp())
    }

    func test_configurationEndPoint() {
        // when
        storage.configurationEndPoint = StubVariables.url

        // then
        XCTAssertNoThrow(try storage.getConfigurationEndPoint())
    }

    func test_no_configurationEndPoint() {
        // when
        storage.configurationEndPoint = nil

        // then
        XCTAssertThrowsError(try storage.getConfigurationEndPoint())
    }

    func test_siteId() {
        // when
        storage.siteID = StubVariables.int

        // then
        XCTAssertNoThrow(try storage.getSiteID())
    }

    func test_error_description() {
        // when
        storage.siteID = nil

        // then
        do {
            _ = try storage.getSiteID()
            XCTFail("Should be fail")
        } catch {
            XCTAssert(error.localizedDescription == "StorageError: No value for key siteID")
        }
    }

    func test_no_siteId() {
        // when
        storage.siteID = nil

        // then
        XCTAssertThrowsError(try storage.getSiteID())
    }

    // MARK: Simple

    func test_isClientHasFirebase() {
        // when
        let value = StubVariables.bool
        storage.isClientHasFirebase = value

        // then
        XCTAssert(storage.isClientHasFirebase == value)
    }

    func test_no_isClientHasFirebase() {
        // then
        XCTAssert(storage.isClientHasFirebase == false)
    }

    func test_isUnregistrationSuccess() {
        // when
        let value = StubVariables.bool
        storage.isUserMigrationSuccess = value

        // then
        XCTAssert(storage.isUserMigrationSuccess == value)
    }

    func test_no_isUnregistrationSuccess() {
        // then
        XCTAssertNil(storage.isUserMigrationSuccess)
    }

    func test_isRegistrationSuccess() {
        // when
        let value = StubVariables.bool
        storage.isRegistrationSuccess = value

        // then
        XCTAssert(storage.isRegistrationSuccess == value)
    }

    func test_no_isRegistrationSuccess() {
        // then
        XCTAssertNil(storage.isRegistrationSuccess)
    }

    func test_isOptRequestSuccess() {
        // when
        let value = StubVariables.bool
        storage.isOptRequestSuccess = value

        // then
        XCTAssert(storage.isOptRequestSuccess == value)
    }

    func test_no_isOptRequestSuccess() {
        // then
        XCTAssert(storage.isOptRequestSuccess == true)
    }

    func test_isFirstConversion() {
        // when
        let value = StubVariables.bool
        storage.isFirstConversion = value

        // then
        XCTAssert(storage.isFirstConversion == value)
    }

    func test_no_isFirstConversion() {
        // then
        XCTAssert(storage.isFirstConversion == false)
    }

    func test_isOptiTrackOptIn() {
        // when
        let value = StubVariables.bool
        storage.isOptiTrackOptIn = value

        // then
        XCTAssert(storage.isOptiTrackOptIn == value)
    }

    func test_no_isOptiTrackOptIn() {
        // then
        XCTAssert(storage.isOptiTrackOptIn == false)
    }

    func test_isSetUserIdSucceed() {
        // when
        let value = StubVariables.bool
        storage.isSetUserIdSucceed = value

        // then
        XCTAssert(storage.isSetUserIdSucceed == value)
    }

    func test_no_isSetUserIdSucceed() {
        // then
        XCTAssert(storage.isSetUserIdSucceed == false)
    }

    func test_realtimeSetUserIdFailed() {
        // when
        let value = StubVariables.bool
        storage.realtimeSetUserIdFailed = value

        // then
        XCTAssert(storage.realtimeSetUserIdFailed == value)
    }

    func test_no_realtimeSetUserIdFailed() {
        // then
        XCTAssert(storage.realtimeSetUserIdFailed == false)
    }

    func test_realtimeSetEmailFailed() {
        // when
        let value = StubVariables.bool
        storage.realtimeSetEmailFailed = value

        // then
        XCTAssert(storage.realtimeSetEmailFailed == value)
    }

    func test_no_realtimeSetEmailFailed() {
        // then
        XCTAssert(storage.realtimeSetEmailFailed == false)
    }

}
