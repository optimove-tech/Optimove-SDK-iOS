import Foundation
import OptimoveCore

public class EmbeddedMessagesService {
    
    public enum Error: LocalizedError {
        case alreadyInitialized
        case notInitialized
        case configurationIsMissing
        case errorSendingRequest
        case errorUserNotSet
        case errorCredentialsNotSet
        
        public var errorDescription: String? {
            switch self {
            case .alreadyInitialized:
                return "The EmbeddedMessagingSDK has already been initialized."
            case .notInitialized:
                return "Embedded messaging has not been initialized."
            case .configurationIsMissing:
                return "Embedded messaging configuration is missing. Please provide valid credentials."
            case .errorSendingRequest:
                return "Unable to retrieve embedded messages."
            case .errorUserNotSet:
                return "User is not set or invalid."
            case .errorCredentialsNotSet:
                return "Credentials for embedded messaging are not set."
            }
        }
    }
    
    static var isSdkRunning: Bool {
        return Optimove.getConfig()?.getPreferenceCenterConfig() != nil
    }
    
    struct Container {
        let containerId: String
        let limit: Int
    }
    
    public enum ResultType {
        case success(EmbeddedMessagesResponse)
        case DeleteSuccess
        case errorUserNotSet
        case errorCredentialsNotSet
        case error(Error)
    }

    public typealias EmbeddedMessagingGetHandler = (_ result: ResultType) -> Void
    public typealias EmbeddedMessagingSetHandler = (_ result: ResultType) -> Void
    public typealias EmbeddedMessagingDeleteHandler = (_ result: ResultType) -> Void
    public typealias EmbeddedMessagingReportHandler = (_ result: ResultType) -> Void

    private static var instance: EmbeddedMessagesService?
    private var storage: OptimoveStorage?
    private var networkClient: NetworkClient?

    public static func getInstance() throws -> EmbeddedMessagesService {
        guard let instance = instance else {
            throw Error.notInitialized
        }
        return instance
    }
    
    struct EmbeddedMessageOptions: Codable {
        var containerId: String
        var limit: Int
    }

    public static func initialize(with optimoveConfig: OptimoveConfig, storage: OptimoveStorage, networkClient: NetworkClient) throws {
        print("🔧 Initializing EmbeddedMessagesService...")

        if instance != nil {
            if optimoveConfig.features.contains(.delayedConfiguration),
               optimoveConfig.getEmbeddedMessagingConfig() == nil {
                throw Error.configurationIsMissing
            }
            print("⚠️ EmbeddedMessagesService already initialized")
            return
        }

        guard instance == nil else {
            assertionFailure(Error.alreadyInitialized.localizedDescription)
            throw Error.alreadyInitialized
        }

        instance = EmbeddedMessagesService(storage: storage, networkClient: networkClient)
        print("✅ EmbeddedMessagesService initialized")
    }

    private init(storage: OptimoveStorage, networkClient: NetworkClient) {
        self.storage = storage
        self.networkClient = networkClient
    }
    
    
    public func setReadAsync(completion: @escaping EmbeddedMessagingGetHandler, embeddedMessage: EmbeddedMessage, isRead: Bool = false) {
        guard let config = Optimove.getConfig()?.getEmbeddedMessagingConfig() else {
            Logger.error("Embedded messaging credentials are not set")
            completion(.error(.errorCredentialsNotSet))
            return
        }

        let customerId = "opt__003"
        let visitorId = "optimove"
        let messageId = embeddedMessage.id

        guard customerId != visitorId else {
            Logger.warn("Customer ID matches visitor ID")
            completion(.error(.errorUserNotSet))
            return
        }

        do {
            let request = try createReadAtMessagesRequest(customerId: customerId, visitorId: visitorId, config: config, message: embeddedMessage, isRead: isRead)
            
            print("request: \(String(describing: request))")
            networkClient?.perform(request) { result in
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        completion(.DeleteSuccess)
                    }
                    
                case .failure(let error):
                    self.logFailedResponse(error)
                    DispatchQueue.main.async {
                        completion(.error(.errorSendingRequest))
                    }
                }
            }

        } catch {
            self.logFailedResponse(error)
            DispatchQueue.main.async {
                completion(.error(.errorSendingRequest))
            }
        }
    }
    

    public func deleteMessagesAsync(completion: @escaping EmbeddedMessagingGetHandler, embeddedMessage: EmbeddedMessage, isRead: Bool = false) {
        guard let config = Optimove.getConfig()?.getEmbeddedMessagingConfig() else {
            Logger.error("Embedded messaging credentials are not set")
            completion(.error(.errorCredentialsNotSet))
            return
        }

        let customerId = "opt__003"
        let visitorId = "optimove"
        let messageId = embeddedMessage.id

        guard customerId != visitorId else {
            Logger.warn("Customer ID matches visitor ID")
            completion(.error(.errorUserNotSet))
            return
        }

        do {
            let request = try createDeleteMessagesRequest(customerId: customerId, visitorId: visitorId, config: config, messageId: messageId)
            
            networkClient?.perform(request) { result in
                switch result {
                case .success(let response):
                    DispatchQueue.main.async {
                        completion(.DeleteSuccess)
                    }
                    
                case .failure(let error):
                    self.logFailedResponse(error)
                    DispatchQueue.main.async {
                        completion(.error(.errorSendingRequest))
                    }
                }
            }

        } catch {
            self.logFailedResponse(error)
            DispatchQueue.main.async {
                completion(.error(.errorSendingRequest))
            }
        }
    }
    
    // MARK: - Get Messages
    
    public func getMessagesAsync(completion: @escaping EmbeddedMessagingGetHandler) {
        guard let config = Optimove.getConfig()?.getEmbeddedMessagingConfig() else {
            Logger.error("Embedded messaging credentials are not set")
            completion(.error(.errorCredentialsNotSet))
            return
        }

        let customerId = "opt__003"
        let visitorId = "optimove" // Or any unique visitor ID

        guard customerId != visitorId else {
            Logger.warn("Customer ID matches visitor ID")
            completion(.error(.errorUserNotSet))
            return
        }

        do {
            let request = try createGetMessagesRequest(customerId: customerId, visitorId: visitorId, config: config)
         
           
            networkClient?.perform(request) { result in
                switch result {
                case .success(let response):
                    do {
                        // Log the response status code or any response info you need
                        print("Response Body: \(response.description)") // If the response has a body that you can log
                        
                        

                        let APIResponse = try response.decode(to: EmbeddedMessagingAPIResponse.self)
                             
                        var containers:  EmbeddedMessagesResponse = [:]
                        for (containerId, messages) in APIResponse.containers {
                            containers[containerId] = EmbeddedMessagingContainer(containerId: containerId, messages: messages)
                        }
                        
                        DispatchQueue.main.async {
                            completion(.success(containers))
                        }
                    } catch {
                        self.logFailedResponse(error)
                        DispatchQueue.main.async {
                            completion(.error(.errorSendingRequest))
                        }
                    }

                case .failure(let error):
                    self.logFailedResponse(error)
                    DispatchQueue.main.async {
                        completion(.error(.errorSendingRequest))
                    }
                }
            }

        } catch {
            logFailedResponse(error)
            DispatchQueue.main.async {
                completion(.error(.errorSendingRequest))
            }
        }
    }
    
    // MARK: - Request Builders

    private func createGetMessagesRequest(customerId: String, visitorId: String, config: EmbeddedMessagingConfig) throws -> NetworkRequest {
        let (region, brandId, tenantId) = getConfigValues(from: config)

        let baseURL = URL(string: "https://optimobile-inbox-srv-\(region).optimove.net")!
        let path = "/api/v1/embedded-messages/Get-Embedded-Messages"
        let queryItems = [
            URLQueryItem(name: "CustomerId", value: customerId),
            URLQueryItem(name: "VisitorId", value: visitorId),
            URLQueryItem(name: "TenantId", value: tenantId),
            URLQueryItem(name: "BrandId", value: brandId)
        ]

        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems

        if let fullURL = components?.url {
            print("📡 Full request URL: \(fullURL.absoluteString)")
        } else {
            print("⚠️ Failed to build full request URL")
        }

        return NetworkRequest(
            method: .post,
            baseURL: baseURL,
            path: path,
            headers: [],
            queryItems: queryItems
        )
    }
    
    private func createDeleteMessagesRequest(customerId: String, visitorId: String, config: EmbeddedMessagingConfig, messageId: String) throws -> NetworkRequest {
        let (region, brandId, tenantId) = getConfigValues(from: config)

        let baseURL = URL(string: "https://optimobile-inbox-srv-\(region).optimove.net")!
        let path = "/api/v1/messages/\(messageId)" // Add messageId directly to the path
        
        // Add query items for TenantId and BrandId
        let queryItems = [
            URLQueryItem(name: "TenantId", value: tenantId),
            URLQueryItem(name: "BrandId", value: brandId)
        ]
        
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems

        if let fullURL = components?.url {
            print("📡 Full request URL: \(fullURL.absoluteString)") // This will print the full URL to the console
        } else {
            print("⚠️ Failed to build full request URL")
        }

        return NetworkRequest(
            method: .delete,
            baseURL: baseURL,
            path: path,
            headers: [],
            queryItems: queryItems
        )
    }
    
    
    private func createReadAtMessagesRequest(
        customerId: String,
        visitorId: String,
        config: EmbeddedMessagingConfig,
        message: EmbeddedMessage,
        isRead: Bool
    ) throws -> NetworkRequest {
        
        let (region, brandId, tenantId) = getConfigValues(from: config)
        let baseURL = URL(string: "https://optimobile-inbox-srv-\(region).optimove.net")!
        let path = "/api/v1/messages/status"

        // Conditionally set readAt timestamp
        let readAtTimestamp: Int? = isRead ? Int(Date().timeIntervalSince1970 * 1000) : nil

        // Create the metric
        let metric = MessageStatusMetric(
            messageId: message.id,
            engagementId: message.engagementId,
            executionDateTime: message.executionDateTime,
            campaignKind: message.campaignKind,
            customerId: customerId,
            readAt: readAtTimestamp
        )

        // Create the request object
        let request = MessageStatusUpdateRequest(
            brandId: brandId,
            tenantId: tenantId,
            statusMetrics: [metric]
        )

        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let bodyData = try encoder.encode(request)

        // Headers
        let headers: [HTTPHeader] = [
            HTTPHeader(field: .contentType, value: .json),
            HTTPHeader(field: .tenantId, value: .tenantId(id: tenantId)) // Optional: only include if the API requires it
        ]

        // No query items now
        let queryItems: [URLQueryItem] = []
        
        print("bodyData: \(String(data: bodyData, encoding: .utf8) )")

        return NetworkRequest(
            method: .put,
            baseURL: baseURL,
            path: path,
            headers: headers,
            queryItems: queryItems,
            httpBody: bodyData
        )
    }
    

    private func getConfigValues(from config: EmbeddedMessagingConfig) -> (region: String, brandId: String, tenantId: String) {
        let region = config.region
        let brandId = config.brandId
        let tenantId = config.tenantId.description
        return (region, brandId, tenantId)
    }

    private func logFailedResponse(_ error: Swift.Error) {
        Logger.error("Request failed: \(error.localizedDescription)")
    }
}
