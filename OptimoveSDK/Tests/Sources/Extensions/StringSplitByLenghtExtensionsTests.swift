// Copiright 2019 Optimove

import XCTest
@testable import OptimoveSDK

class StringSplitByLenghtExtensionsTests: XCTestCase {

    func test_output_strideS_count() {
        // given
        let inputStringLenght = 1000
        let inputString = Array(repeating: "a", count: inputStringLenght).joined()
        let outputStrideLenght = 255
        let expectedCount = Int((Float(inputStringLenght) / Float(outputStrideLenght)).rounded(.up))

        // when
        let outputStrides = inputString.split(by: outputStrideLenght)

        // then
        XCTAssert(outputStrides.count == expectedCount,
                  "Expected \(expectedCount). Actual \(outputStrides.count)")
    }

    func test_output_stride_count() {
        // given
        let inputStringLenght = 1000
        let inputString = Array(repeating: "a", count: inputStringLenght).joined()
        let outputStrideLenght = 255
        let expectedCount = Int((Float(inputStringLenght) / Float(outputStrideLenght)).rounded(.down))

        // when
        let outputStrides = inputString.split(by: outputStrideLenght)

        // then
        for i in 0..<expectedCount {
            XCTAssert(outputStrides[i].count == outputStrideLenght,
                      "Expected \(outputStrideLenght). Actual \(outputStrides[i].count)")
        }
    }

    func test_stride_on_edge() {
        // given
        let inputStringLenght = 255
        let inputString = Array(repeating: "a", count: inputStringLenght).joined()
        let outputStrideLenght = 255
        let expectedCount = Int((Float(inputStringLenght) / Float(outputStrideLenght)).rounded(.up))

        // when
        let outputStrides = inputString.split(by: outputStrideLenght)

        // then
        XCTAssert(outputStrides.count == expectedCount,
                  "Expected \(expectedCount). Actual \(outputStrides.count)")
    }


}
