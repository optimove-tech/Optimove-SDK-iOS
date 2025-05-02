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

        mockStorage.set(value: "adam_b@optimove.com", key: .customerID)
        mockStorage.set(value: "Optimove", key: .visitorID)

        let mockOptimoveConfig = MockOptimoveConfig(embeddedMessagingConfig: mockConfig).config
        Optimove.initialize(with: mockOptimoveConfig)

        service = EmbeddedMessagesService(storage: mockStorage, networkClient: mockNetworkClient)
    }

    func testShouldBeTrue() {
        XCTAssertTrue(true, "This test always passes because 'true' is always true.")
    }

    func testGetMessagesAsync_callsSuccessCompletion() throws {
        // Given
        let expectation = self.expectation(description: "getMessagesAsync calls completion with success")

        let message = EmbeddedMessage(
            customerId: "adam_b@optimove.com",
            isVisitor: false,
            templateId: 1,
            title: "Test Title",
            content: "Test message",
            media: nil,
            readAt: nil,
            url: nil,
            engagementId: "eng123",
            payload: [:],
            campaignKind: 1,
            executionDateTime: "2025-01-01T12:00:00Z",
            messageLayoutType: nil,
            expiryDate: nil,
            containerId: "test-container",
            id: "test-id",
            createdAt: 1234567890,
            updatedAt: nil,
            deletedAt: nil
        )

        let apiResponse = EmbeddedMessagingAPIResponse(containers: ["test-container": [message]])
        let jsonData = try JSONEncoder().encode(apiResponse)

        // 👇 Using test-only extension to bypass inaccessible initializer
        let mockNetworkResponse = NetworkResponse<Data?>.testMock(statusCode: 200, body: jsonData)
        mockNetworkClient.mockResponse = .success(mockNetworkResponse)

        // When
        service.getMessagesAsync { result in
            // Then
            switch result {
            case .success(let containers):
                XCTAssertEqual(containers["test-container"]?.messages.first?.id, "test-id")
                expectation.fulfill()
            case .error(let error):
                XCTFail("Expected success but got error: \(error)")
            case .DeleteSuccess:
                XCTFail("Expected success but got DeleteSuccess")
            case .errorUserNotSet:
                XCTFail("Expected success but got errorUserNotSet")
            case .errorCredentialsNotSet:
                XCTFail("Expected success but got errorCredentialsNotSet")
            }
        }

        wait(for: [expectation], timeout: 2)
    }
}
