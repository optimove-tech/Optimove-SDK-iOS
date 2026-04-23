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
            embeddedMessagingConfig: embeddedMessagingConfig,
            authTokenProvider: nil
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
            payload: "{\"key\":\"string\"}",
            campaignKind: 1,
            executionDateTime: Date(timeIntervalSince1970: 1735732800),
            messageLayoutType: nil,
            expiryDate: nil,
            containerId: "test-container",
            id: id,
            createdAt: createdAt,      // ✅ Now a Date
            updatedAt: updatedAt,      // ✅ Now a Date
            deletedAt: nil
        )
    }
    // MARK: - Test decoding real server response with ISO 8601 dates
    func testGetMessagesAsync_decodesISO8601DatesFromServerResponse() throws {
        let expectation = self.expectation(description: "decodes ISO 8601 dates")

        let json = """
        {"containers":{"stuart":[{
            "id":"3842b5cd-9751-4cf1-9f9b-9636b38182c6",
            "containerId":"stuart",
            "customerId":"adam_b@optimove.com",
            "isVisitor":false,
            "templateId":1744118753960,
            "title":"Testing stuart container",
            "content":"here is a test template",
            "media":"B04wM4Y7/yGxgri37bzmGBknvP4wgQdDy123Z9HfEUqYw9gmN.png",
            "readAt":"2026-03-08T12:13:51.305+00:00",
            "url":"https://google.com",
            "engagementId":"1000",
            "payload":{"key1":"value1","key2":"value2"},
            "campaignKind":1,
            "executionDateTime":"2026-03-08T11:58:54.739155Z",
            "messageLayoutType":0,
            "expiryDate":"2026-04-07T23:59:00Z",
            "createdAt":"2025-04-08T13:32:16.000+00:00",
            "updatedAt":"2026-03-08T12:13:50.573+00:00",
            "deletedAt":null
        }]}}
        """.data(using: .utf8)

        let mockNetworkResponse = NetworkResponse<Data?>.testMock(statusCode: 200, body: json)
        mockNetworkClient.mockResponse = .success(mockNetworkResponse)

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        fmt.timeZone = TimeZone(identifier: "UTC")

        service.getMessagesAsync { result in
            switch result {
            case .successMessages(let containers):
                guard let msg = containers["stuart"]?.messages.first else {
                    XCTFail("Expected message in 'stuart' container")
                    return
                }

                // identity
                XCTAssertEqual(msg.id, "3842b5cd-9751-4cf1-9f9b-9636b38182c6")
                XCTAssertEqual(msg.containerId, "stuart")
                XCTAssertEqual(msg.templateId, 1744118753960)
                XCTAssertEqual(msg.title, "Testing stuart container")
                XCTAssertEqual(msg.content, "here is a test template")
                XCTAssertEqual(msg.engagementId, "1000")
                XCTAssertEqual(msg.url, "https://google.com")

                // dates — all formats including microseconds and 2-digit fractional
                XCTAssertEqual(fmt.string(from: msg.executionDateTime), "2026-03-08T11:58:54") // 6-digit fractional
                XCTAssertEqual(fmt.string(from: msg.createdAt), "2025-04-08T13:32:16")
                XCTAssertEqual(fmt.string(from: msg.updatedAt), "2026-03-08T12:13:50")        // 3-digit fractional
                XCTAssertEqual(fmt.string(from: msg.readAt!), "2026-03-08T12:13:51")
                XCTAssertEqual(fmt.string(from: msg.expiryDate!), "2026-04-07T23:59:00") // no fractional

                // payload serialized to string
                XCTAssertTrue(msg.payload.contains("key1"))
                XCTAssertTrue(msg.payload.contains("value1"))

                expectation.fulfill()
            default:
                XCTFail("Expected successMessages but got \(result)")
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

// MARK: - Auth-specific Tests

final class EmbeddedMessagingAuthTests: XCTestCase {

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
    }

    private func makeTestMessage() -> EmbeddedMessage {
        let createdAt = Date(timeIntervalSince1970: 1752663497311 / 1000)
        let updatedAt = Date(timeIntervalSince1970: 1752663497311 / 1000)

        return EmbeddedMessage(
            customerId: "adam_b@optimove.com",
            isVisitor: false,
            templateId: 1,
            title: "Test Title",
            content: "Test content",
            media: nil,
            readAt: nil,
            url: nil,
            engagementId: "eng123",
            payload: "{\"key\":\"string\"}",
            campaignKind: 1,
            executionDateTime: Date(timeIntervalSince1970: 1735732800),
            messageLayoutType: nil,
            expiryDate: nil,
            containerId: "test-container",
            id: "test-id",
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: nil
        )
    }

    // EmbeddedMessagingAPIResponse is intentionally decode-only (it remaps
    // raw wire shape → public model). For tests we craft the wire JSON directly.
    private func makeMockGetMessagesResponseData() -> Data {
        let json = """
        {"containers":{"test-container":[{
            "id":"test-id",
            "containerId":"test-container",
            "customerId":"adam_b@optimove.com",
            "isVisitor":false,
            "templateId":1,
            "title":"Test Title",
            "content":"Test content",
            "media":null,
            "readAt":null,
            "url":null,
            "engagementId":"eng123",
            "payload":{"key":"string"},
            "campaignKind":1,
            "executionDateTime":"2025-01-01T12:00:00Z",
            "messageLayoutType":null,
            "expiryDate":null,
            "createdAt":"2025-07-16T12:00:00Z",
            "updatedAt":"2025-07-16T12:00:00Z",
            "deletedAt":null
        }]}}
        """
        return json.data(using: .utf8)!
    }

    func test_getMessagesAsync_noAuthManager_sendsRequestWithoutJWT() throws {
        let service = EmbeddedMessagesService(storage: mockStorage, networkClient: mockNetworkClient, authManager: nil)

        let jsonData = makeMockGetMessagesResponseData()
        let mockNetworkResponse = NetworkResponse<Data?>.testMock(statusCode: 200, body: jsonData)
        mockNetworkClient.mockResponse = .success(mockNetworkResponse)

        let exp = expectation(description: "getMessagesAsync completes")

        service.getMessagesAsync { result in
            switch result {
            case .successMessages:
                let headers = self.mockNetworkClient.lastRequest?.headers ?? []
                let jwtHeader = headers.first(where: { $0.field == "X-User-JWT" })
                XCTAssertNil(jwtHeader, "Should NOT include X-User-JWT header when no authManager")
            default:
                XCTFail("Expected successMessages but got \(result)")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 2)
    }

    func test_getMessagesAsync_authConfigured_success_includesJWT() throws {
        let authManager = AuthManager { userId, completion in
            XCTAssertEqual(userId, "adam_b@optimove.com")
            completion("jwt-123", nil)
        }
        let service = EmbeddedMessagesService(storage: mockStorage, networkClient: mockNetworkClient, authManager: authManager)

        let jsonData = makeMockGetMessagesResponseData()
        let mockNetworkResponse = NetworkResponse<Data?>.testMock(statusCode: 200, body: jsonData)
        mockNetworkClient.mockResponse = .success(mockNetworkResponse)

        let exp = expectation(description: "getMessagesAsync with JWT completes")

        service.getMessagesAsync { result in
            switch result {
            case .successMessages:
                let headers = self.mockNetworkClient.lastRequest?.headers ?? []
                let jwtHeader = headers.first(where: { $0.field == "X-User-JWT" })
                XCTAssertNotNil(jwtHeader, "Should include X-User-JWT header")
                XCTAssertEqual(jwtHeader?.value, "jwt-123")
            default:
                XCTFail("Expected successMessages but got \(result)")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 2)
    }

    func test_getMessagesAsync_authConfigured_getTokenFails_returnsError() {
        let authManager = AuthManager { _, completion in
            completion(nil, NSError(domain: "auth", code: 401))
        }
        let service = EmbeddedMessagesService(storage: mockStorage, networkClient: mockNetworkClient, authManager: authManager)

        let exp = expectation(description: "getMessagesAsync fails when auth fails")

        service.getMessagesAsync { result in
            switch result {
            case .error:
                // Fail-closed: auth failure → error returned to caller
                break
            default:
                XCTFail("Expected error but got \(result)")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 2)

        XCTAssertNil(mockNetworkClient.lastRequest, "No network request should be made when auth fails")
    }

    func test_deleteMessagesAsync_authConfigured_includesJWT() {
        let authManager = AuthManager { _, completion in
            completion("jwt-delete-456", nil)
        }
        let service = EmbeddedMessagesService(storage: mockStorage, networkClient: mockNetworkClient, authManager: authManager)

        let mockNetworkResponse = NetworkResponse<Data?>.testMock(statusCode: 200, body: nil)
        mockNetworkClient.mockResponse = .success(mockNetworkResponse)

        let exp = expectation(description: "deleteMessagesAsync with JWT completes")

        service.deleteMessagesAsync(message: makeTestMessage()) { result in
            switch result {
            case .success:
                let headers = self.mockNetworkClient.lastRequest?.headers ?? []
                let jwtHeader = headers.first(where: { $0.field == "X-User-JWT" })
                XCTAssertNotNil(jwtHeader, "Should include X-User-JWT header for delete")
                XCTAssertEqual(jwtHeader?.value, "jwt-delete-456")
            default:
                XCTFail("Expected success but got \(result)")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 2)
    }

    func test_setAsReadAsync_authConfigured_includesJWT() {
        let authManager = AuthManager { _, completion in
            completion("jwt-read-789", nil)
        }
        let service = EmbeddedMessagesService(storage: mockStorage, networkClient: mockNetworkClient, authManager: authManager)

        let mockNetworkResponse = NetworkResponse<Data?>.testMock(statusCode: 200, body: nil)
        mockNetworkClient.mockResponse = .success(mockNetworkResponse)

        let exp = expectation(description: "setAsReadAsync with JWT completes")

        service.setAsReadAsync(message: makeTestMessage(), isRead: true) { result in
            switch result {
            case .success:
                let headers = self.mockNetworkClient.lastRequest?.headers ?? []
                let jwtHeader = headers.first(where: { $0.field == "X-User-JWT" })
                XCTAssertNotNil(jwtHeader, "Should include X-User-JWT header for setAsRead")
                XCTAssertEqual(jwtHeader?.value, "jwt-read-789")
            default:
                XCTFail("Expected success but got \(result)")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 2)
    }

    func test_reportClickMetricAsync_authConfigured_includesJWT() {
        let authManager = AuthManager { _, completion in
            completion("jwt-click-101", nil)
        }
        let service = EmbeddedMessagesService(storage: mockStorage, networkClient: mockNetworkClient, authManager: authManager)

        let mockNetworkResponse = NetworkResponse<Data?>.testMock(statusCode: 200, body: nil)
        mockNetworkClient.mockResponse = .success(mockNetworkResponse)

        let exp = expectation(description: "reportClickMetricAsync with JWT completes")

        service.reportClickMetricAsync(message: makeTestMessage()) { result in
            switch result {
            case .success:
                let headers = self.mockNetworkClient.lastRequest?.headers ?? []
                let jwtHeader = headers.first(where: { $0.field == "X-User-JWT" })
                XCTAssertNotNil(jwtHeader, "Should include X-User-JWT header for reportClick")
                XCTAssertEqual(jwtHeader?.value, "jwt-click-101")
            default:
                XCTFail("Expected success but got \(result)")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 2)
    }
}
