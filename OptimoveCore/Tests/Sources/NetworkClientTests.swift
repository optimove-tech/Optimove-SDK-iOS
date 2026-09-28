//  Copyright © 2019 Optimove. All rights reserved.

import Mocker
@testable import OptimoveCore
import OptimoveTest
import XCTest

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

    func test_perform_addsXOptimoveAuthCapableHeader() {
        // given
        let headerExpectation = expectation(description: "X-Optimove-Auth-Capable and X-Optimove-Platform headers should be present")

        var mock = Mock(
            url: StubVariables.url,
            contentType: .json,
            statusCode: 200,
            data: [.get: Data()]
        )
        mock.onRequestHandler = OnRequestHandler(requestCallback: { urlRequest in
            let authCapable = urlRequest.value(forHTTPHeaderField: "X-Optimove-Auth-Capable")
            XCTAssertEqual(authCapable, "1", "Every request should include X-Optimove-Auth-Capable: 1")
            let platform = urlRequest.value(forHTTPHeaderField: "X-Optimove-Platform")
            XCTAssertEqual(platform, "ios", "Every request should include X-Optimove-Platform: ios")
            headerExpectation.fulfill()
        })
        Mocker.register(mock)

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
        wait(for: [headerExpectation, success], timeout: defaultTimeout)
    }
}
