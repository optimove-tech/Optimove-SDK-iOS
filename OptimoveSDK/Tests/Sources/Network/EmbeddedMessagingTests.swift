import XCTest
import OptimoveTest
import OptimoveCore
@testable import OptimoveSDK

// MARK: - Test-only Extension for NetworkResponse
extension NetworkResponse {
    static func testMock(statusCode: Int = 200, body: Body) -> NetworkResponse<Body> {
        return unsafeBitCast((statusCode, body), to: NetworkResponse<Body>.self)
    }
}

// MARK: - Mock Network Client
class MockNetworkClient: NetworkClient {
    var mockResponse: Result<NetworkResponse<Data?>, NetworkError>?

    var lastRequest: NetworkRequest?
    var lastURLRequest: URLRequest?

    // Add this property to capture body bytes
    var lastRequestBody: Data?

    func perform(_ request: NetworkRequest, _ completion: @escaping NetworkServiceCompletion) {
        lastRequest = request

        do {
            let urlRequest = try request.asURLRequest()
            lastURLRequest = urlRequest
            lastRequestBody = urlRequest.httpBody  // Capture the body here
        } catch {
            lastURLRequest = nil
            lastRequestBody = nil
        }

        if let response = mockResponse {
            completion(response)
        } else {
            completion(.failure(.requestFailed))
        }
    }
}
// MARK: - Mock network request
extension NetworkRequest {
    func asURLRequest() throws -> URLRequest {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw NSError(domain: "Invalid baseURL", code: 0)
        }
        components.path = path ?? ""
        if let queryItems = queryItems {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw NSError(domain: "Invalid URL components", code: 0)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue

        headers?.forEach { urlRequest.addValue($0.value, forHTTPHeaderField: $0.field) }

        urlRequest.httpBody = httpBody

        return urlRequest
    }

    var url: URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.path = path ?? ""
        components.queryItems = queryItems
        return components.url ?? baseURL
    }
}
// MARK: - Mock Optimove Config
struct MockOptimoveConfig {
    let config: OptimoveConfig

    init(embeddedMessagingConfig: EmbeddedMessagingConfig) {
        self.config = OptimoveConfig(
            features: [.embeddedMessaging],
            tenantInfo: nil,
            optimobileConfig: nil,
            preferenceCenterConfig: nil,
            embeddedMessagingConfig: embeddedMessagingConfig
        )
    }
}

func assertValidContext(_ context: Any?, file: StaticString = #file, line: UInt = #line) {
    guard let contextDict = context as? [String: Any],
          let messageId = contextDict["messageId"] as? String,
          let containerId = contextDict["containerId"] as? String else {
        XCTFail("Expected context with messageId and containerId", file: file, line: line)
        return
    }

    XCTAssertFalse(messageId.isEmpty, "Expected messageId in context", file: file, line: line)
    XCTAssertFalse(containerId.isEmpty, "Expected containerId in context", file: file, line: line)
}

// MARK: - Test Class
final class EmbeddedMessagingTests: XCTestCase {

    var service: EmbeddedMessagesService!
    var mockStorage: MockOptimoveStorage!
    var mockConfig: EmbeddedMessagingConfig!
    var mockNetworkClient: MockNetworkClient!

    override func setUp() {
        super.setUp()

        mockStorage = MockOptimoveStorage()
        mockConfig = EmbeddedMessagingConfig(region: "eu", tenantId: 456, brandId: "123")
        mockNetworkClient = MockNetworkClient()

        mockStorage[.customerID] = "adam_b@optimove.com"
        mockStorage[.visitorID] = "Optimove"

        let mockOptimoveConfig = MockOptimoveConfig(embeddedMessagingConfig: mockConfig).config
        Optimove.initialize(with: mockOptimoveConfig)

        service = EmbeddedMessagesService(storage: mockStorage, networkClient: mockNetworkClient)
    }
    // MARK: - Make test Message
    func makeTestMessage(id: String, title: String, content: String) -> EmbeddedMessage {
        // Convert milliseconds to Date
        let createdAt = Date(timeIntervalSince1970: 1752663497311 / 1000)
        let updatedAt = Date(timeIntervalSince1970: 1752663497311 / 1000)

        return EmbeddedMessage(
            customerId: "adam_b@optimove.com",
            isVisitor: false,
            templateId: 1,
            title: title,
            content: content,
            media: nil,
            readAt: nil,
            url: nil,
            engagementId: "eng123",
            payload: ["key": AnyCodable("string")],
            campaignKind: 1,
            executionDateTime: "2025-01-01T12:00:00Z",
            messageLayoutType: nil,
            expiryDate: nil,
            containerId: "test-container",
            id: id,
            createdAt: createdAt,      // ✅ Now a Date
            updatedAt: updatedAt,      // ✅ Now a Date
            deletedAt: nil
        )
    }
    // MARK: - Test Get Messages
    func testGetMessagesAsync_callsSuccessCompletion() throws {
        // Given
        let expectation = self.expectation(description: "getMessagesAsync calls completion with success")

        let message = makeTestMessage(id: "test-id", title: "Test Title", content: "Test message")

        let apiResponse = EmbeddedMessagingAPIResponse(containers: ["test-container": [message]])
        let jsonData = try JSONEncoder().encode(apiResponse)

        // 👇 Using test-only extension to bypass inaccessible initializer
        let mockNetworkResponse = NetworkResponse<Data?>.testMock(statusCode: 200, body: jsonData)
        mockNetworkClient.mockResponse = .success(mockNetworkResponse)

        // When
        service.getMessagesAsync { result in
            // Then
            switch result {
            case .successMessages(let containers):
                XCTAssertEqual(containers["test-container"]?.messages.first?.id, "test-id")
                expectation.fulfill()
            case .error(let error):
                XCTFail("Expected success but got error: \(error)")
            case .success:
                XCTFail("Expected successMessages but got Success")
            case .errorUserNotSet:
                XCTFail("Expected success but got errorUserNotSet")
            case .errorCredentialsNotSet:
                XCTFail("Expected success but got errorCredentialsNotSet")
            }
        }

        wait(for: [expectation], timeout: 2)
    }
    // MARK: - Test Delete Message Async
    func testDeleteMessage_callsSuccessCompletion() throws {
        // Given
        let expectation = self.expectation(description: "ReportClickMetrics calls completion with Success")

        let message = makeTestMessage(id: "test-id", title: "Test Title", content: "Test message")

        let mockNetworkResponse = NetworkResponse<Data?>.testMock(statusCode: 200, body: nil)
        mockNetworkClient.mockResponse = .success(mockNetworkResponse)

        // When
        service.deleteMessagesAsync(message: message, completion: { result in
            switch result {
            case .success:
                // Check captured request
                guard let request = self.mockNetworkClient.lastRequest else {
                    XCTFail("No request captured")
                    return
                }

                // Check HTTP Method
                XCTAssertEqual(request.method, .post)

                // Check URL path
                XCTAssertEqual(request.url.path, "/api/v2/events/report")

                // Check URL query parameters
                let components = URLComponents(url: request.url, resolvingAgainstBaseURL: false)
                let queryItems = components?.queryItems ?? []

                XCTAssertTrue(queryItems.contains(URLQueryItem(name: "TenantId", value: "456")))
                XCTAssertTrue(queryItems.contains(URLQueryItem(name: "BrandId", value: "123")))

          
                // Check HTTP body data in the captured URLRequest
                if let body = self.mockNetworkClient.lastRequestBody {
                    do {
                        // Decode JSON body into an array of dictionaries
                        let jsonArray = try JSONSerialization.jsonObject(with: body, options: []) as? [[String: Any]]

                        guard let firstEvent = jsonArray?.first else {
                            XCTFail("Expected at least one event in request body")
                            return
                        }

                    assertValidContext(firstEvent["context"])
                        

                    } catch {
                        XCTFail("Failed to parse request body as JSON: \(error)")
                    }
                } else {
                    XCTFail("Expected non-nil body with message ID")
                }
                expectation.fulfill()

            default:
                XCTFail("Expected Success but got \(result)")
            }
        })

        wait(for: [expectation], timeout: 2)
    }
   
    // MARK: - Test Set As Read Async
    func testSetAsReadAsync_callsSuccessCompletion() throws {
        // Given
        let expectation = self.expectation(description: "setAsReadAsync calls completion with Success")

        let message = makeTestMessage(id: "test-id", title: "Test Title", content: "Test message")

        let mockNetworkResponse = NetworkResponse<Data?>.testMock(statusCode: 200, body: nil)
        mockNetworkClient.mockResponse = .success(mockNetworkResponse)

        // When
        service.setAsReadAsync(message: message, isRead: true, completion: { result in
            switch result {
            case .success:
                // Check captured request
                guard let request = self.mockNetworkClient.lastRequest else {
                    XCTFail("No request captured")
                    return
                }

                // Check HTTP Method
                XCTAssertEqual(request.method, .post)

                // Check URL path
                XCTAssertEqual(request.url.path, "/api/v2/events/report")

                // Check URL query parameters
                let components = URLComponents(url: request.url, resolvingAgainstBaseURL: false)
                let queryItems = components?.queryItems ?? []

                XCTAssertTrue(queryItems.contains(URLQueryItem(name: "TenantId", value: "456")))
                XCTAssertTrue(queryItems.contains(URLQueryItem(name: "BrandId", value: "123")))

          
                // Check HTTP body data in the captured URLRequest
                if let body = self.mockNetworkClient.lastRequestBody {
                    do {
                        // Decode JSON body into an array of dictionaries
                        let jsonArray = try JSONSerialization.jsonObject(with: body, options: []) as? [[String: Any]]

                        guard let firstEvent = jsonArray?.first else {
                            XCTFail("Expected at least one event in request body")
                            return
                        }

                        // ✅ Check eventType is "read"
                        XCTAssertEqual(firstEvent["eventType"] as? String, "embedded-message.read", "Expected eventType to be 'read'")

                        assertValidContext(firstEvent["context"])

                    } catch {
                        XCTFail("Failed to parse request body as JSON: \(error)")
                    }
                } else {
                    XCTFail("Expected non-nil body with message ID")
                }
                expectation.fulfill()

            default:
                XCTFail("Expected Success but got \(result)")
            }
        })

        wait(for: [expectation], timeout: 2)
    }
    
    
    
    // MARK: - Test Report click metrics Async
    func testReportClickMetricsc_callsSuccessCompletion() throws {
        // Given
        let expectation = self.expectation(description: "ReportClickMetrics calls completion with Success")

        let message = makeTestMessage(id: "test-id", title: "Test Title", content: "Test message")

        let mockNetworkResponse = NetworkResponse<Data?>.testMock(statusCode: 200, body: nil)
        mockNetworkClient.mockResponse = .success(mockNetworkResponse)

        // When
        service.reportClickMetricAsync(message: message, completion: { result in
            switch result {
            case .success:
                // Check captured request
                guard let request = self.mockNetworkClient.lastRequest else {
                    XCTFail("No request captured")
                    return
                }

                // Check HTTP Method
                XCTAssertEqual(request.method, .post)

                // Check URL path
                XCTAssertEqual(request.url.path, "/api/v2/events/report")

                // Check URL query parameters
                let components = URLComponents(url: request.url, resolvingAgainstBaseURL: false)
                let queryItems = components?.queryItems ?? []

                XCTAssertTrue(queryItems.contains(URLQueryItem(name: "TenantId", value: "456")))
                XCTAssertTrue(queryItems.contains(URLQueryItem(name: "BrandId", value: "123")))

          
                // Check HTTP body data in the captured URLRequest
                if let body = self.mockNetworkClient.lastRequestBody {
                    do {
                        // Decode JSON body into an array of dictionaries
                        let jsonArray = try JSONSerialization.jsonObject(with: body, options: []) as? [[String: Any]]

                        guard let firstEvent = jsonArray?.first else {
                            XCTFail("Expected at least one event in request body")
                            return
                        }

                        // ✅ Check eventType is "read"
                        XCTAssertEqual(firstEvent["eventType"] as? String, "embedded-message.clicked", "Expected eventType to be 'clicked'")

                        assertValidContext(firstEvent["context"])

                    } catch {
                        XCTFail("Failed to parse request body as JSON: \(error)")
                    }
                } else {
                    XCTFail("Expected non-nil body with message ID")
                }
                expectation.fulfill()

            default:
                XCTFail("Expected Success but got \(result)")
            }
        })

        wait(for: [expectation], timeout: 2)
    }
    

}
