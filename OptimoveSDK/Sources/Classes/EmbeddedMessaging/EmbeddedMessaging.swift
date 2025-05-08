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
        return Optimove.getConfig()?.getEmbeddedMessagingConfig() != nil
    }

    
    public enum ResultType {
        case successMessages(EmbeddedMessagesResponse)
        case Success
        case errorUserNotSet
        case errorCredentialsNotSet
        case error(Error)
    }

    public typealias EmbeddedMessagingGetHandler = (_ result: ResultType) -> Void
    public typealias EmbeddedMessagingSetHandler = (_ result: ResultType) -> Void
    public typealias EmbeddedMessagingDeleteHandler = (_ result: ResultType) -> Void
    public typealias EmbeddedMessagingReportHandler = (_ result: ResultType) -> Void

   
    internal static var instance: EmbeddedMessagesService?
    private var storage: OptimoveStorage?
    private var networkClient: NetworkClient?
    private var payload: String = ""
    
    internal static func getInstance() throws -> EmbeddedMessagesService {
        guard let instance = instance else {
            throw Error.notInitialized
        }
        return instance
    }
    
    public func getPayload() -> String {
        return payload
    }

    public func getJSONPayload() throws -> Any {
        let data = Data(payload.utf8)
        return try JSONSerialization.jsonObject(with: data, options: [])
    }

    public func getPayload<T: Decodable>(_ type: T.Type) throws -> T {
        let data = Data(payload.utf8)
        return try JSONDecoder().decode(T.self, from: data)
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

    internal init(storage: OptimoveStorage, networkClient: NetworkClient) {
        self.storage = storage
        self.networkClient = networkClient
    }
    
    
    private func getConfigValues(from config: EmbeddedMessagingConfig) -> (region: String, brandId: String, tenantId: String) {
        let region = config.region
        let brandId = config.brandId
        let tenantId = config.tenantId.description
        return (region, brandId, tenantId)
    }
    
    /// Gets the embedded messages from the server.
    ///
    /// - Parameter containerRequestOptions: The options for the container request.
    /// - Returns: The embedded messages response.
    // MARK: - Get Messages
    public func getMessagesAsync(
        containers: [ContainerRequestOptions]? = nil,
        completion: @escaping EmbeddedMessagingGetHandler,
    ) {
        guard let config = Optimove.getConfig()?.getEmbeddedMessagingConfig() else {
            Logger.error("Embedded messaging credentials are not set")
            completion(.error(.errorCredentialsNotSet))
            return
        }
        
        guard
            let customerId = try? storage?.getCustomerID(),
            let visitorId = try? storage?.getVisitorID(),
            customerId != visitorId else {
            Logger.warn("Customer ID is not set")
            completion(.errorUserNotSet)
            return
        }
        
        do {
            let request = try createGetEmbeddedMessagesRequest(
                customerId: customerId,
                visitorId: visitorId,
                config: config,
                containers: containers
            )
            
            networkClient?.perform(request) { result in
                switch result {
                case .success(let response):
                    do {
                        let APIResponse = try response.decode(to: EmbeddedMessagingAPIResponse.self)
                        var containers: EmbeddedMessagesResponse = [:]
                        for (containerId, messages) in APIResponse.containers {
                            containers[containerId] = EmbeddedMessagingContainer(containerId: containerId, messages: messages)
                        }

                        DispatchQueue.main.async {
                            completion(.successMessages(containers))
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
    
    /// Deletes the given message from the server.
    ///
    /// - Parameter message: The message to delete.
    /// - Returns: A promise indicating the completion of the delete operation.
    // MARK: - Delete Messages
    public func deleteMessagesAsync(message: EmbeddedMessage, isRead: Bool = false, completion: @escaping EmbeddedMessagingGetHandler, ) {
        guard let config = Optimove.getConfig()?.getEmbeddedMessagingConfig() else {
            Logger.error("Embedded messaging credentials are not set")
            completion(.error(.errorCredentialsNotSet))
            return
        }

        guard
            let customerId = try? storage?.getCustomerID(),
            let visitorId = try? storage?.getVisitorID(),
            customerId != visitorId else {
            Logger.warn("Customer ID is not set")
            completion(.errorUserNotSet)
            return
        }

        do {
            let request = try createDeleteMessagesRequest(customerId: customerId, visitorId: visitorId, config: config, messageId: message.id)
            
            networkClient?.perform(request) { result in
                switch result {
                case .success(_):
                    DispatchQueue.main.async {
                        completion(.Success)
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
    
    /// Updates the read status of the given message on the server.
    ///
    /// - Parameters:
    ///   - message: The message to update.
    ///   - isRead: The new read status of the message.
    /// - Returns: A promise indicating the completion of the read status update.
    // MARK: - Set Read Async
    public func setAsReadAsync(message: EmbeddedMessage, isRead: Bool = false, completion: @escaping EmbeddedMessagingGetHandler,) {
        guard let config = Optimove.getConfig()?.getEmbeddedMessagingConfig() else {
            Logger.error("Embedded messaging credentials are not set")
            completion(.error(.errorCredentialsNotSet))
            return
        }

        guard
            let customerId = try? storage?.getCustomerID(),
            let visitorId = try? storage?.getVisitorID(),
            customerId != visitorId else {
            Logger.warn("Customer ID is not set")
            completion(.errorUserNotSet)
            return
        }

        do {
            let request = try createReadAtMessagesRequest(customerId: customerId, visitorId: visitorId, config: config, message: message, isRead: isRead)
            
            print("request: \(String(describing: request))")
            networkClient?.perform(request) { result in
                switch result {
                case .success(_):
                    DispatchQueue.main.async {
                        completion(.Success)
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
    
    /// Reports a click metric for the given message.
    ///
    /// - Parameter message: The message to report the click metric for.
    /// - Returns: A promise indicating the completion of the click metric report.
    // MARK: - Report Click metric Async
    public func reportClickMetricAsync(message: EmbeddedMessage, completion: @escaping EmbeddedMessagingGetHandler,) {
        guard let config = Optimove.getConfig()?.getEmbeddedMessagingConfig() else {
            Logger.error("Embedded messaging credentials are not set")
            completion(.error(.errorCredentialsNotSet))
            return
        }
        
        guard
            let customerId = try? storage?.getCustomerID(),
            let visitorId = try? storage?.getVisitorID(),
            customerId != visitorId else {
            Logger.warn("Customer ID is not set")
            completion(.errorUserNotSet)
            return
        }

        do {
            let request = try createReportMetricsRequest(customerId: customerId, visitorId: visitorId, config: config, message: message)
            
            print("request: \(String(describing: request))")
            networkClient?.perform(request) { result in
                switch result {
                case .success(_):
                    DispatchQueue.main.async {
                        completion(.Success)
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
    

    // MARK: - Create Get Messages Request
    private func createGetEmbeddedMessagesRequest(
        customerId: String,
        visitorId: String,
        config: EmbeddedMessagingConfig,
        containers: [ContainerRequestOptions]? = nil
    ) throws -> NetworkRequest {
        
        let (region, brandId, tenantId) = getConfigValues(from: config)
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "CustomerId", value: customerId),
            URLQueryItem(name: "VisitorId", value: visitorId),
            URLQueryItem(name: "TenantId", value: tenantId),
            URLQueryItem(name: "BrandId", value: brandId)
        ]
        
        let baseURL = URL(string: "https://optimobile-inbox-srv-\(region).optimove.net")!
        let path = "/api/v1/embedded-messages/Get-Embedded-Messages"

        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(containers)

        let headers: [HTTPHeader] = [
            HTTPHeader(field: .contentType, value: .json)
        ]

        return NetworkRequest(
            method: .post,
            baseURL: baseURL,
            path: path,
            headers: headers,
            queryItems: queryItems,
            httpBody: bodyData
        )
    }
    
    
    // MARK: - Create Delete Messages Request
    private func createDeleteMessagesRequest(customerId: String, visitorId: String, config: EmbeddedMessagingConfig, messageId: String) throws -> NetworkRequest {
        let (region, brandId, tenantId) = getConfigValues(from: config)

        let baseURL = URL(string: "https://optimobile-inbox-srv-\(region).optimove.net")!
        let path = "/api/v1/messages/\(messageId)"
        
        let queryItems = [
            URLQueryItem(name: "TenantId", value: tenantId),
            URLQueryItem(name: "BrandId", value: brandId)
        ]
        
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems

        return NetworkRequest(
            method: .delete,
            baseURL: baseURL,
            path: path,
            headers: [],
            queryItems: queryItems
        )
    }
    
    // MARK: - Create ReadAt Messages Request
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

        let readAtTimestamp: Int? = isRead ? Int(Date().timeIntervalSince1970 * 1000) : nil

        let metric = ReadMessageStatusMetric(
            messageId: message.id,
            engagementId: message.engagementId,
            executionDateTime: message.executionDateTime,
            campaignKind: message.campaignKind,
            customerId: customerId,
            readAt: readAtTimestamp
        )

        let request = ReadAtMetricRequest(
            brandId: brandId,
            tenantId: tenantId,
            statusMetrics: [metric]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let bodyData = try encoder.encode(request)

        // Headers
        let headers: [HTTPHeader] = [
            HTTPHeader(field: .contentType, value: .json),
            HTTPHeader(field: .tenantId, value: .tenantId(id: tenantId))
        ]

        // No query items now
        let queryItems: [URLQueryItem] = []
        
        return NetworkRequest(
            method: .put,
            baseURL: baseURL,
            path: path,
            headers: headers,
            queryItems: queryItems,
            httpBody: bodyData
        )
    }
    
     // MARK: - Create report metrics Request
    private func createReportMetricsRequest(
        customerId: String,
        visitorId: String,
        config: EmbeddedMessagingConfig,
        message: EmbeddedMessage
    ) throws -> NetworkRequest {
        
        let (region, brandId, tenantId) = getConfigValues(from: config)
        let baseURL = URL(string: "https://optimobile-inbox-srv-\(region).optimove.net")!
        let path = "/api/v1/messages/metrics"


        let currentDate = Date()
        let dateFormatter = ISO8601DateFormatter()
        let formattedCurrentTimestamp = dateFormatter.string(from: currentDate)

        let metric = ClickMetric(
            messageId: message.id,
            engagementId: message.engagementId,
            executionDateTime: message.executionDateTime,
            campaignKind: message.campaignKind,
            customerId: customerId,
            now: formattedCurrentTimestamp
        )

        let request = ClickMetricRequest(
            brandId: brandId,
            tenantId: tenantId,
            statusMetrics: [metric]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let bodyData = try encoder.encode(request)

        // Headers
        let headers: [HTTPHeader] = [
            HTTPHeader(field: .contentType, value: .json),
            HTTPHeader(field: .tenantId, value: .tenantId(id: tenantId))
        ]

        // No query items now
        let queryItems: [URLQueryItem] = []
        
        return NetworkRequest(
            method: .put,
            baseURL: baseURL,
            path: path,
            headers: headers,
            queryItems: queryItems,
            httpBody: bodyData
        )
    }
    
    // MARK: - Log Failed Response
    private func logFailedResponse(_ error: Swift.Error) {
        Logger.error("Request failed: \(error.localizedDescription)")
    }
    
    
}
