import Mocker
@testable import OptimoveCore
@testable import OptimoveSDK
import XCTest

class EmbeddedMessagesServiceTests: XCTestCase {

    var mockStorage: MockOptimoveStorage!
    var mockNetworkClient: NetworkClientImpl!
    var mockConfig: OptimoveConfig!
    
    override func setUp() {
        super.setUp()
        
        // Initialize mockStorage and network client
        mockStorage = MockOptimoveStorage()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockingURLProtocol.self]
        mockNetworkClient = NetworkClientImpl(configuration: configuration)

        // Create a mock config for testing
        mockConfig = OptimoveConfig(features: .embeddedMessaging,
                                    tenantInfo: OptimoveTenantInfo(tenantToken: "testToken", configName: "testConfig"),
                                    optimobileConfig: nil,
                                    preferenceCenterConfig: nil,
                                    embeddedMessagingConfig: EmbeddedMessagingConfig(region: "dev", tenantId: 593, brandId: "9abb8d6d-62ed-42d1-97d1-c82d15f9c1fc"))
        
        // Reset singleton state before each test
        EmbeddedMessagesService.instance = nil
    }

    override func tearDown() {
        mockStorage = nil
        mockNetworkClient = nil
        mockConfig = nil
        super.tearDown()
    }

    // Test for successfully retrieving messages
    func testGetMessagesAsync_Success() {
        // Given: Mocking a successful response
        let mockResponseData = "{ \"containers\": { \"container1\": [\"message1\", \"message2\"] } }".data(using: .utf8)!
        Mocker.register(
            Mock(
                url: URL(string: "https://optimobile-inbox-srv-us-east-1.optimove.net/api/v1/embedded-messages/Get-Embedded-Messages")!,
                dataType: .json,
                statusCode: 200,
                data: [.get: mockResponseData]
            )
        )

        // When: Trying to get messages
        let expectation = self.expectation(description: "Get messages completed")
        
        // Initialize the service with mock config
        do {
            try EmbeddedMessagesService.initialize(with: mockConfig, storage: mockStorage, networkClient: mockNetworkClient)
        } catch {
            XCTFail("Initialization failed with error: \(error)")
            return
        }

        // Call the getInstance method without passing any argument
        do {
            let service = try EmbeddedMessagesService.getInstance()
            
            // Then handle the completion via other methods (e.g., fetchMessages)
            service.getMessagesAsync { result in
                switch result {
                case .success(let containers):
                    XCTAssertEqual(containers.count, 1)
                    XCTAssertTrue(containers.keys.contains("container1"))
                    expectation.fulfill()
                case .error:
                    XCTFail("Expected success, but got error.")
                case .DeleteSuccess:
                    XCTFail("Expected success, but got error.")
                case .errorUserNotSet:
                    XCTFail("Expected success, but got error.")
                case .errorCredentialsNotSet:
                    XCTFail("Expected success, but got error.")
                }
            }
        } catch {
            XCTFail("Failed to get instance with error: \(error)")
        }

        // Then: Verify success case was called
        wait(for: [expectation], timeout: 1.0)
    }

    // Test for successfully deleting a message
    func testDeleteMessagesAsync_Success() {
        // Given: Mocking successful response for message deletion
        Mocker.register(
            Mock(
                url: URL(string: "https://optimobile-inbox-srv-us-east-1.optimove.net/api/v1/messages/message1")!,
                dataType: .json,
                statusCode: 200,
                data: [.delete: Data()]
            )
        )

        // Example mock EmbeddedMessage
        let mockMessage = EmbeddedMessage(
            customerId: "customer123",
            isVisitor: true,
            templateId: 1001,
            title: "Welcome to Our Service",
            content: "Thank you for signing up! We are happy to have you.",
            media: "https://example.com/media/image.jpg",
            readAt: nil,
            url: "https://example.com/welcome",
            engagementId: "engagement123",
            payload: ["key1": "value1", "key2": "value2"],
            campaignKind: 1,
            executionDateTime: "2025-04-24T10:00:00Z",
            messageLayoutType: 2,
            expiryDate: "2025-05-01T00:00:00Z",
            containerId: "container123",
            id: "message123",
            createdAt: 1682620800,  // Example timestamp
            updatedAt: "2025-04-24T09:00:00Z",
            deletedAt: nil
        )
        // When: Trying to delete a message
        let expectation = self.expectation(description: "Delete message completed")
        
        // Initialize the service with mock config
        do {
            try EmbeddedMessagesService.initialize(with: mockConfig, storage: mockStorage, networkClient: mockNetworkClient)
        } catch {
            XCTFail("Initialization failed with error: \(error)")
            return
        }

        do {
            let service = try EmbeddedMessagesService.getInstance()
            
            service.deleteMessagesAsync(completion: { result in
                if case .DeleteSuccess = result {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected DeleteSuccess, but got a different result.")
                }
            }, message: mockMessage)
        } catch {
            XCTFail("Failed to get instance with error: \(error)")
        }

        // Then: Verify successful deletion
        wait(for: [expectation], timeout: 1.0)
    }

    // Mock storage for testing purposes
    class MockOptimoveStorage: OptimoveStorage {
        // Properties for mock data
        var mockCustomerID: String = "customer123"
        var mockVisitorID: String = "visitor123"
        var mockInstallationID: String = "installation123"
        var mockTenantToken: String = "tenant123"
        var mockVersion: String = "1.0"
        
        // MARK: - Conforming to StorageValue
        var installationID: String? {
            get { return mockInstallationID }
            set { mockInstallationID = newValue ?? "" }
        }
        
        var customerID: String? {
            get { return mockCustomerID }
            set { mockCustomerID = newValue ?? "" }
        }
        
        var visitorID: String? {
            get { return mockVisitorID }
            set { mockVisitorID = newValue ?? "" }
        }
        
        var tenantToken: String? {
            get { return mockTenantToken }
            set { mockTenantToken = newValue ?? "" }
        }
        
        var version: String? {
            get { return mockVersion }
            set { mockVersion = newValue ?? "" }
        }

        // MARK: - StorageValue methods
        func getConfigurationEndPoint() throws -> URL {
            return URL(string: "https://example.com")!
        }
        
        func getCustomerID() throws -> String {
            return mockCustomerID
        }
        
        func getVisitorID() throws -> String {
            return mockVisitorID
        }
        
        func getTenantToken() throws -> String {
            return mockTenantToken
        }
        
        func getVersion() throws -> String {
            return mockVersion
        }

        // MARK: - Conforming to KeyValueStorage
        private var storage: [StorageKey: Any] = [:]
        
        func set(value: Any?, key: StorageKey) {
            storage[key] = value
        }
        
        func value(for key: StorageKey) -> Any? {
            return storage[key]
        }
        
        subscript<T>(key: StorageKey) -> T? {
            get { return storage[key] as? T }
            set { storage[key] = newValue }
        }
        
        // MARK: - Conforming to FileStorage
        func isExist(fileName: String, isTemporary: Bool) -> Bool {
            return fileName == "testFile" // Mock file check
        }
        
        func save<T: Codable>(data: T, toFileName fileName: String, isTemporary: Bool) throws {
            // Simulate saving data
            print("Saving data to \(fileName)")
        }
        
        func load<T: Codable>(fileName: String, isTemporary: Bool) throws -> T {
            // Simulate loading data
            print("Loading data from \(fileName)")
            return Data() as! T  // Return empty data for mock
        }
        
        func delete(fileName: String, isTemporary: Bool) throws {
            // Simulate file deletion
            print("Deleting file: \(fileName)")
        }
    }
}
