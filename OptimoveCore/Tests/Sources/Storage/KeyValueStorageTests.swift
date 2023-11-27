//  Copyright © 2019 Optimove. All rights reserved.

@testable import OptimoveCore
import OptimoveTest
import XCTest

class MockKeyValueStorage: KeyValueStorage {
    var assertFunction: ((_ value: Any?, _ key: StorageKey) -> Void)?
    var state: [StorageKey: Any?] = [:]

    func set(value: Any?, key: StorageKey) {
        state[key] = value
        assertFunction?(value, key)
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

    func isExist(fileName: String) -> Bool {
        return storage[fileName] != nil
    }

    func save<T: Codable>(data: T, toFileName: String) throws {
        storage[toFileName] = try JSONEncoder().encode(data)
    }

    func saveData(data: Data, toFileName: String) throws {
        storage[toFileName] = data
    }

    func load<T: Codable>(fileName: String) throws -> T {
        return try JSONDecoder().decode(T.self, from: unwrap(storage[fileName]))
    }

    func loadData(fileName: String) throws -> Data {
        return try unwrap(storage[fileName])
    }

    func delete(fileName: String) throws {
        return storage[fileName] = nil
    }
}

class KeyValueStorageTests: XCTestCase {
    var storage: OptimoveStorage!
    let stub_data = Data(capacity: 42)

    override func setUp() {
        storage = StorageFacade(
            keyValureStorage: MockKeyValueStorage(),
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

    func test_firstRunTimestamp() {
        // when
        storage.firstRunTimestamp = 42

        // then
        XCTAssertNoThrow(try storage.getFirstRunTimestamp())
    }

    func test_no_firstRunTimestamp() {
        // when
        storage.firstVisitTimestamp = nil

        // then
        XCTAssertThrowsError(try storage.getFirstRunTimestamp())
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

    func test_isSettingUserSuccess() {
        // when
        let value = StubVariables.bool
        storage.isSettingUserSuccess = value

        // then
        XCTAssert(storage.isSettingUserSuccess == value)
    }

    func test_no_isSettingUserSuccess() {
        // then
        XCTAssertNil(storage.isSettingUserSuccess)
    }
}
