//  Copyright © 2019 Optimove. All rights reserved.

import OptimoveSDK
import OptimoveTest
import XCTest

class TenantConfigTests: XCTestCase, FileAccessible {
    // Use `com.apple.dt.xctest.tool` bundle identifier in the config file, just for this test case.
    let fileName = "dev.tid.107.optipush.json"

    // Check data sample by test decoder
    func test_decode() {
        // given
        let decoder = JSONDecoder()

        // then
        XCTAssertNoThrow(try decoder.decode(TenantConfig.self, from: data))
    }

    // Check data sample by test decoder, then tests encoder.
    func test_decode_encode() {
        // given
        let decoder = JSONDecoder()
        let config = try! decoder.decode(TenantConfig.self, from: data)
        let encoder = JSONEncoder()

        // then
        XCTAssertNoThrow(try encoder.encode(config))
    }

    // Check data sample by test decoder, then tests encoder, and decode again in a reason to make sure
    // that the custom decoder and encoder were not broke anything.
    func test_decode_encode_decode() {
        // given
        let decoder = JSONDecoder()
        let config = try! decoder.decode(TenantConfig.self, from: data)
        let encoder = JSONEncoder()
        let data = try! encoder.encode(config)

        // then
        XCTAssertNoThrow(try decoder.decode(TenantConfig.self, from: data))
    }
}
