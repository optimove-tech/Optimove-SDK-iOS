import XCTest
import OptimoveTest
import OptimoveCore
@testable import OptimoveSDK

// MARK: - Mock Network Client
class MockNetworkClient: NetworkClient {
    var mockResponse: Result<NetworkResponse<Data?>, NetworkError>?

    func perform(_ request: NetworkRequest, _ completion: @escaping NetworkServiceCompletion) {
        // Return the mocked response
        if let response = mockResponse {
            completion(response)
        } else {
            // Simulate a default failure response
            let failureResponse: Result<NetworkResponse<Data?>, NetworkError> = .failure(.requestFailed)
            completion(failureResponse)
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

        let mockOptimoveConfig = MockOptimoveConfig(embeddedMessagingConfig: mockConfig).config

        do {
            try EmbeddedMessagesService.initialize(
                with: mockOptimoveConfig,
                storage: mockStorage,
                networkClient: mockNetworkClient
            )
            service = try EmbeddedMessagesService.getInstance()
        } catch {
            XCTFail("Failed to initialize EmbeddedMessagesService: \(error)")
        }
    }

    func testShouldBeTrue() {
        
    
        XCTAssertTrue(true, "This test always passes because 'true' is always true.")
    }
    
    
}
