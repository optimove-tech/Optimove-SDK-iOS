//  Copyright © 2019 Optimove. All rights reserved.

import Mocker
@testable import OptimoveCore
import XCTest
import OptimoveTest

class NetworkClientTests: XCTestCase {
    func test_get_request() {
        // given
        Mocker.register(
            Mock(
                url: StubVariables.url,
                dataType: .json,
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
        client.perform(request) { result in
            switch result {
            case .success:
                success.fulfill()
            case .failure:
                XCTFail()
            }
        }

        // then
        wait(for: [success], timeout: defaultTimeout)
    }

    func test_post_request() {
        // given

        Mocker.register(
            Mock(
                url: StubVariables.url,
                dataType: .json,
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
        client.perform(request) { result in
            switch result {
            case .success:
                success.fulfill()
            case .failure:
                XCTFail()
            }
        }

        // then
        wait(for: [success], timeout: defaultTimeout)
    }
}
