import XCTest
@testable import OptimoveSDK

final class EmbeddedMessagesServiceTests: XCTestCase {
    
    class URLProtocolStub: URLProtocol {
        static var responseData: Data?
        static var responseStatusCode: Int = 200

        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

        override func startLoading() {
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: URLProtocolStub.responseStatusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data = URLProtocolStub.responseData {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }

    override func setUp() {
        super.setUp()
        URLProtocol.registerClass(URLProtocolStub.self)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(URLProtocolStub.self)
        super.tearDown()
    }

    func test_getEmbeddedMessagesAsync_returnsSuccessWithData() {
        // Arrange
        let expectedResponseData = """
        {
            "messages": [
                { "id": "msg1", "content": "Hello" }
            ]
        }
        """.data(using: .utf8)!

        URLProtocolStub.responseData = expectedResponseData

        let expectation = self.expectation(description: "Wait for response")

        // Act
        EmbeddedMessagesService.getEmbeddedMessagesAsync(
            customerId: "test-customer",
            visitorId: "test-visitor",
            tenantId: "3013",
            brandId: "brand-123",
            region: "dev"
        ) { result in
            switch result {
            case .success(let data):
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                XCTAssertEqual((json?["messages"] as? [[String: Any]])?.first?["id"] as? String, "msg1")
            case .failure:
                XCTFail("Expected success but got failure")
            }
            expectation.fulfill()
        }

        // Assert
        wait(for: [expectation], timeout: 1.0)
    }
}
