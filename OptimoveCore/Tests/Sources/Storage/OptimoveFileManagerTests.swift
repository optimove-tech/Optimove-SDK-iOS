// Copiright 2019 Optimove

import XCTest
@testable import OptimoveCore

final class MockedFileManager: FileManager {

    private let groupedURL =  URL(fileURLWithPath: "grouped")
    private let sharedURL =  URL(fileURLWithPath: "shared")
    private var state: [String: Data] = [:]

    override func containerURL(forSecurityApplicationGroupIdentifier groupIdentifier: String) -> URL? {
        return groupedURL
    }

    override func urls(for directory: FileManager.SearchPathDirectory,
                       in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        return [sharedURL]
    }
//
//    override func fileExists(atPath path: String) -> Bool {
//        return state[path] != nil
//    }
//
//    override func contents(atPath path: String) -> Data? {
//        return state[path]
//    }
//
//    override func createDirectory(at url: URL,
//                                  withIntermediateDirectories createIntermediates: Bool,
//                                  attributes: [FileAttributeKey : Any]? = nil) throws {
//        // Do nothing
//    }
//
//    override func createFile(atPath path: String,
//                             contents data: Data?,
//                             attributes attr: [FileAttributeKey : Any]? = nil) -> Bool {
//        state[path] = data
//        return true
//    }
//
//    override func removeItem(at URL: URL) throws {
//        state[URL.absoluteString] = nil
//    }

}

class OptimoveFileManagerTests: XCTestCase {

    let fileName = "StubCodable"
    var fileStorage: FileStorage!
    let fileManager = MockedFileManager()

    override func setUp() {
        fileStorage = try! FileStorageImpl(
            bundleIdentifier: Bundle.main.bundleIdentifier!,
            fileManager: fileManager
        )
    }

    func test_save_encodable_shared() {
        save_encodable(shared: true)
    }

    func test_save_encodable_no_shared() {
        save_encodable(shared: false)
    }

    func save_encodable(shared: Bool) {
        // given
        let model = StubCodable()

        // when
        XCTAssertNoThrow(try fileStorage.save(data: model, toFileName: fileName, shared: shared))

        // then
        XCTAssert(fileStorage.isExist(fileName: fileName, shared: shared))
    }

    func test_load_data_shared() {
        load_data(shared: true)
    }

    func test_load_data_no_shared() {
        load_data(shared: false)
    }

    func load_data(shared: Bool) {
        // given
        save_encodable(shared: shared)

        // then
        XCTAssertNoThrow(try fileStorage.load(fileName: fileName, shared: shared))
        let data = try! fileStorage.load(fileName: fileName, shared: shared)
        XCTAssertNoThrow(try JSONDecoder().decode(StubCodable.self, from: data))
    }

    func test_delete_shared() {
        delete_file(shared: true)
    }

    func test_delete_no_shared() {
        delete_file(shared: false)
    }

    func delete_file(shared: Bool) {
        // given
        save_encodable(shared: shared)

        // when
        XCTAssertNoThrow(try fileStorage.delete(fileName: fileName, shared: shared))

        // then
        XCTAssert(fileStorage.isExist(fileName: fileName, shared: shared) == false)
    }

    func test_delete_not_existed_file_shared() {
        delete_not_existed_file(shared: true)
    }

    func test_delete_not_existed_file_no_shared() {
        delete_not_existed_file(shared: false)
    }

    func delete_not_existed_file(shared: Bool) {
        // check if file exist as result of an another test.
        if fileStorage.isExist(fileName: fileName, shared: shared) {
            try? fileStorage.delete(fileName: fileName, shared: shared)
        }

        // then
        XCTAssertThrowsError(try fileStorage.delete(fileName: fileName, shared: shared))
    }

}

private struct StubCodable: Codable {
    let name = "name"
    let value = "value"
    let parameters: [String: String] = [
        "key": "value"
    ]
}
