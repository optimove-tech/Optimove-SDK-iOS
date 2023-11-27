//  Copyright © 2019 Optimove. All rights reserved.

@testable import OptimoveCore
import XCTest
import OptimoveTest

class GlobalConfigTests: XCTestCase, FileAccessible {
    let fileName = "configs.json"

    // Check data sample by test decoder
    func test_decode() {
        // given
        let decoder = JSONDecoder()

        // then
        XCTAssertNoThrow(try decoder.decode(GlobalConfig.self, from: data))
    }

    // Check data sample by test decoder, then tests encoder.
    func test_decode_encode() {
        // given
        let decoder = JSONDecoder()
        let config = try! decoder.decode(GlobalConfig.self, from: data)
        let encoder = JSONEncoder()

        // then
        XCTAssertNoThrow(try encoder.encode(config))
    }

    // Check data sample by test decoder, then tests encoder, and decode again in a reason to make sure
    // that the custom decoder and encoder were not broke anything.
    func test_decode_encode_decode() {
        // given
        let decoder = JSONDecoder()
        let config = try! decoder.decode(GlobalConfig.self, from: data)
        let encoder = JSONEncoder()
        let data = try! encoder.encode(config)

        // then
        XCTAssertNoThrow(try decoder.decode(GlobalConfig.self, from: data))
    }
}
