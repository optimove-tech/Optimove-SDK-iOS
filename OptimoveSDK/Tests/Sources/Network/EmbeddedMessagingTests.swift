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

    func perform(_ request: NetworkRequest, _ completion: @escaping NetworkServiceCompletion) {
        if let response = mockResponse {
            completion(response)
        } else {
            completion(.failure(.requestFailed))
        }
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
            payload: "string",
            campaignKind: 1,
            executionDateTime: ISO8601DateFormatter().date(from: "2025-01-01T12:00:00Z")!,
            messageLayoutType: nil,
            expiryDate: nil,
            containerId: "test-container",
            id: id,
            createdAt: Date(timeIntervalSince1970: 1715097600),
            updatedAt: Date(timeIntervalSince1970: 1715097600),
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
            case .Success:
                XCTFail("Expected successMessages but got Success")
            case .errorUserNotSet:
                XCTFail("Expected success but got errorUserNotSet")
            case .errorCredentialsNotSet:
                XCTFail("Expected success but got errorCredentialsNotSet")
            }
        }

        wait(for: [expectation], timeout: 2)
    }
    // MARK: - Test Delete Messages
    func testDeleteMessagesAsync_callsDeleteSuccessCompletion() throws {
        // Given
        let expectation = self.expectation(description: "deleteMessagesAsync calls completion with DeleteSuccess")

        let message = makeTestMessage(id: "test-id", title: "Test Title", content: "Test message")


        let mockNetworkResponse = NetworkResponse<Data?>.testMock(statusCode: 204, body: nil)
        mockNetworkClient.mockResponse = .success(mockNetworkResponse)

        // When
        service.deleteMessagesAsync(message: message, completion: { result in
            // Then
            switch result {
            case .Success:
                expectation.fulfill()
            case .successMessages(_):
                XCTFail("Expected Success but got successMessages")
            case .error(let error):
                XCTFail("Expected DeleteSuccess but got error: \(error)")
            case .errorUserNotSet:
                XCTFail("Expected DeleteSuccess but got errorUserNotSet")
            case .errorCredentialsNotSet:
                XCTFail("Expected DeleteSuccess but got errorCredentialsNotSet")
            }
        })

        wait(for: [expectation], timeout: 2)
    }
    // MARK: - Test Set As Read Async
    func testSetAsReadAsync_callsSuccessCompletion() throws {
            // Given
            let expectation = self.expectation(description: "setAsReadAsync calls completion with DeleteSuccess")

            let message = makeTestMessage(id: "test-id", title: "Test Title", content: "Test message")

            // Mock network response to simulate successful update
            let mockNetworkResponse = NetworkResponse<Data?>.testMock(statusCode: 200, body: nil)
            mockNetworkClient.mockResponse = .success(mockNetworkResponse)

            // When
        service.setAsReadAsync(message: message, isRead: true, completion: { result in
            // Then
            switch result {
            case .Success:
                expectation.fulfill()
            case .successMessages(_):
                XCTFail("Expected Success but got successMessages")
            case .error(let error):
                XCTFail("Expected DeleteSuccess but got error: \(error)")
            case .errorUserNotSet:
                XCTFail("Expected DeleteSuccess but got errorUserNotSet")
            case .errorCredentialsNotSet:
                XCTFail("Expected DeleteSuccess but got errorCredentialsNotSet")
            }
        })

            wait(for: [expectation], timeout: 2)
        }
    
    // MARK: - Test Repost Click Metrics
    func testReportClickMetricAsync_callsSuccessCompletion() throws {
           // Given
           let expectation = self.expectation(description: "reportClickMetricAsync calls completion with DeleteSuccess")

        let message = makeTestMessage(id: "test-id", title: "Test Title", content: "Test message")


           // Mock network response to simulate successful click metric reporting
           let mockNetworkResponse = NetworkResponse<Data?>.testMock(statusCode: 200, body: nil)
           mockNetworkClient.mockResponse = .success(mockNetworkResponse)

           // When
        service.reportClickMetricAsync(message: message, completion: { result in
            // Then
            switch result {
            case .Success:
                expectation.fulfill()
            case .successMessages(_):
                XCTFail("Expected Success but got successMessages")
            case .error(let error):
                XCTFail("Expected DeleteSuccess but got error: \(error)")
            case .errorUserNotSet:
                XCTFail("Expected DeleteSuccess but got errorUserNotSet")
            case .errorCredentialsNotSet:
                XCTFail("Expected DeleteSuccess but got errorCredentialsNotSet")
            }
        })

           wait(for: [expectation], timeout: 2)
       }

}
