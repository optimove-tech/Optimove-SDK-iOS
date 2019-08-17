//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import Mocker
@testable import OptimoveSDK

class NetworkClientTests: XCTestCase {

    func test_get_request() {
        // given
        Mocker.register(
            Mock(
                url: StubVariables.url,
                contentType: .json,
                statusCode: 200,
                data: [.get: Data()]
            )
        )

        // and
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockingURLProtocol.self]
        let client = NetworkClientImpl(configuration: configuration)

        // and
        let request = NetworkRequest(method: .get, baseURL: StubVariables.url)

        // when
        let success = expectation(description: "Result with success was not generated")
        client.perform(request) { (result) in
            switch result {
            case .success(_):
                success.fulfill()
            case .failure(_):
                XCTFail()
            }
        }

        // then
        wait(for: [success], timeout: expectationTimeout)
    }

    func test_post_request() {
        // given
        Mocker.register(
            Mock(
                url: StubVariables.url,
                contentType: .json,
                statusCode: 200,
                data: [.post: Data()]
            )
        )

        // and
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockingURLProtocol.self]
        let client = NetworkClientImpl(configuration: configuration)

        // and
        let request = NetworkRequest(method: .post, baseURL: StubVariables.url)

        // when
        let success = expectation(description: "Result with success was not generated")
        client.perform(request) { (result) in
            switch result {
            case .success(_):
                success.fulfill()
            case .failure(_):
                XCTFail()
            }
        }

        // then
        wait(for: [success], timeout: expectationTimeout)
    }
}
