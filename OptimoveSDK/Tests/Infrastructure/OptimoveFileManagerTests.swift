// Copiright 2019 Optimove

import XCTest
@testable import OptimoveSDK

class OptimoveFileManagerTests: XCTestCase {

    let fileName = "StubCodable"
    var fileManager: OptimoveFileStorage!

    override func setUp() {
        fileManager = OptimoveFileManager(
            fileManager: .default
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
        XCTAssertNoThrow(try fileManager.save(data: model, toFileName: fileName, shared: shared))

        // then
        XCTAssertNoThrow(try fileManager.isExist(fileName: fileName, shared: shared))
        XCTAssert(try! fileManager.isExist(fileName: fileName, shared: shared))
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
        XCTAssertNoThrow(try fileManager.load(fileName: fileName, shared: shared))
        let data = try! fileManager.load(fileName: fileName, shared: shared)
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
        XCTAssertNoThrow(try fileManager.delete(fileName: fileName, shared: shared))

        // then
        XCTAssert(try! fileManager.isExist(fileName: fileName, shared: shared) == false)
    }

    func test_delete_not_existed_file_shared() {
        delete_not_existed_file(shared: true)
    }

    func test_delete_not_existed_file_no_shared() {
        delete_not_existed_file(shared: false)
    }

    func delete_not_existed_file(shared: Bool) {
        // check if file exist as result of an another test.
        if let isExist = try? fileManager.isExist(fileName: fileName, shared: shared), isExist {
            try? fileManager.delete(fileName: fileName, shared: shared)
        }

        // then
        XCTAssertThrowsError(try fileManager.delete(fileName: fileName, shared: shared))
    }

}

private struct StubCodable: Codable {
    let name = "name"
    let value = "value"
    let parameters: [String: String] = [
        "key": "value"
    ]
}
