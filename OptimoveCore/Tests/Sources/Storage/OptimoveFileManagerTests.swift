//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveCore

final class MockedFileManager: FileManager {

    private let groupedURL = URL(fileURLWithPath: "grouped")
    private let sharedURL = URL(fileURLWithPath: "shared")
    private var state: [String: Data] = [:]

    override func containerURL(forSecurityApplicationGroupIdentifier groupIdentifier: String) -> URL? {
        return groupedURL
    }

    override func urls(for directory: FileManager.SearchPathDirectory,
                       in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        return [sharedURL]
    }
}

class OptimoveFileManagerTests: XCTestCase {

    let fileName = "StubCodable"
    var fileStorage: FileStorage!
    let fileManager = MockedFileManager()

    override func setUp() {
        fileStorage = try! FileStorageImpl(
            url: try! FileManager.optimoveURL()
        )
    }

    func test_save_encodable_shared() {
        save_encodable()
    }

    func test_save_encodable_no_shared() {
        save_encodable()
    }

    func save_encodable() {
        // given
        let model = StubCodable()

        // when
        XCTAssertNoThrow(try fileStorage.save(data: model, toFileName: fileName))

        // then
        XCTAssert(fileStorage.isExist(fileName: fileName))
    }

    func test_load_data_shared() throws {
        try load_data(isGroupContainer: true)
    }

    func test_load_data_no_shared() throws {
        try load_data(isGroupContainer: false)
    }

    func load_data(isGroupContainer: Bool) throws {
        // given
        save_encodable()

        // then
        XCTAssertNotNil(try fileStorage.loadData(fileName: fileName))
        let stub: StubCodable = try fileStorage.load(fileName: fileName)
        XCTAssertNotNil(stub)
    }

    func test_delete_shared() {
        delete_file(isGroupContainer: true)
    }

    func test_delete_no_shared() {
        delete_file(isGroupContainer: false)
    }

    func delete_file(isGroupContainer: Bool) {
        // given
        save_encodable()

        // when
        XCTAssertNoThrow(try fileStorage.delete(fileName: fileName))

        // then
        XCTAssert(fileStorage.isExist(fileName: fileName) == false)
    }

    func test_delete_not_existed_file_shared() {
        delete_not_existed_file()
    }

    func test_delete_not_existed_file_no_shared() {
        delete_not_existed_file()
    }

    func delete_not_existed_file() {
        // check if file exist as result of an another test.
        if fileStorage.isExist(fileName: fileName) {
            try? fileStorage.delete(fileName: fileName)
        }

        // then
        XCTAssertThrowsError(try fileStorage.delete(fileName: fileName))
    }

}

private struct StubCodable: Codable {
    var name = "name"
    var value = "value"
    var parameters: [String: String] = [
        "key": "value"
    ]
}
