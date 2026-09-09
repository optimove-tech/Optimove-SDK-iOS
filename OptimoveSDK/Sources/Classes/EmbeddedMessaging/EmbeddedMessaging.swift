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
        case success
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
    private var authManager: AuthManager?
    private var payload: [String: Any] = [:]
    
    private func handleRequestError(_ error: Swift.Error) {
        logFailedResponse(error)
    }

    public static func getInstance() throws -> EmbeddedMessagesService {
        guard let instance = instance else {
            throw Error.notInitialized
        }
        return instance
    }
    
    public func getPayload() -> [String: Any] {
        return payload
    }

    public func getJSONPayload() -> Any {
        return payload
    }

    public func getPayload<T: Decodable>(_ type: T.Type) throws -> T {
        let data = try JSONSerialization.data(withJSONObject: payload, options: [])
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    public static func initialize(with optimoveConfig: OptimoveConfig, storage: OptimoveStorage, networkClient: NetworkClient, authManager: AuthManager? = nil) throws {
        Logger.info("Initializing EmbeddedMessagesService...")

        if instance != nil {
            if optimoveConfig.features.contains(.delayedConfiguration),
               optimoveConfig.getEmbeddedMessagingConfig() == nil {
                throw Error.configurationIsMissing
            }
            Logger.warn("EmbeddedMessagesService already initialized")
            return
        }

        guard instance == nil else {
            assertionFailure(Error.alreadyInitialized.localizedDescription)
            throw Error.alreadyInitialized
        }

        instance = EmbeddedMessagesService(storage: storage, networkClient: networkClient, authManager: authManager)
        Logger.info("EmbeddedMessagesService initialized")
    }

    internal init(storage: OptimoveStorage, networkClient: NetworkClient, authManager: AuthManager? = nil) {
        self.storage = storage
        self.networkClient = networkClient
        self.authManager = authManager
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
        completion: @escaping EmbeddedMessagingGetHandler
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

        resolveJWT(userId: customerId, action: { [weak self] jwt in
            guard let self = self else { return }
            do {
                let request = try self.createGetEmbeddedMessagesRequest(
                    customerId: customerId,
                    visitorId: visitorId,
                    config: config,
                    containers: containers,
                    jwt: jwt
                )

                self.networkClient?.perform(request) { result in
                    switch result {
                    case .success(let response):
                        do {
                            let apiResponse = try response.decode(to: EmbeddedMessagingAPIResponse.self)
                            var containers: EmbeddedMessagesResponse = [:]
                            for (containerId, messages) in apiResponse.containers {
                                containers[containerId] = EmbeddedMessagingContainer(containerId: containerId, messages: messages)
                            }

                            DispatchQueue.main.async {
                                completion(.successMessages(containers))
                            }
                        } catch {
                            self.handleRequestError(error)
                            DispatchQueue.main.async {
                                completion(.error(.errorSendingRequest))
                            }
                        }

                    case .failure(let error):
                        self.handleRequestError(error)
                        DispatchQueue.main.async {
                            completion(.error(.errorSendingRequest))
                        }
                    }
                }

            } catch {
                self.handleRequestError(error)
                DispatchQueue.main.async {
                    completion(.error(.errorSendingRequest))
                }
            }
        }, onFailure: { _ in
            DispatchQueue.main.async {
                completion(.error(.errorSendingRequest))
            }
        })
    }
    
    /// Deletes the given message from the server.
    ///
    /// - Parameter message: The message to delete.
    /// - Returns: A promise indicating the completion of the delete operation.
    // MARK: - Delete Messages
    public func deleteMessagesAsync(
        message: EmbeddedMessage,
        isRead: Bool = false,
        completion: @escaping EmbeddedMessagingGetHandler
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

        resolveJWT(userId: customerId, action: { [weak self] jwt in
            guard let self = self else { return }
            do {
                let request = try self.createReportEventRequest(
                    customerId: customerId,
                    visitorId: visitorId,
                    message: message,
                    event: EventType.delete,
                    config: config,
                    jwt: jwt
                )

                self.networkClient?.perform(request) { result in
                    switch result {
                    case .success:
                        DispatchQueue.main.async {
                            completion(.success)
                        }

                    case .failure(let error):
                        self.handleRequestError(error)
                        DispatchQueue.main.async {
                            completion(.error(.errorSendingRequest))
                        }
                    }
                }

            } catch {
                self.handleRequestError(error)
                DispatchQueue.main.async {
                    completion(.error(.errorSendingRequest))
                }
            }
        }, onFailure: { _ in
            DispatchQueue.main.async {
                completion(.error(.errorSendingRequest))
            }
        })
    }
    
    /// Updates the read status of the given message on the server.
    ///
    /// - Parameters:
    ///   - message: The message to update.
    ///   - isRead: The new read status of the message.
    /// - Returns: A promise indicating the completion of the read status update.
    // MARK: - Set Read Async
    public func setAsReadAsync(
        message: EmbeddedMessage,
        isRead: Bool = false,
        completion: @escaping EmbeddedMessagingGetHandler
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

        resolveJWT(userId: customerId, action: { [weak self] jwt in
            guard let self = self else { return }
            do {
                let request = try self.createReportEventRequest(
                    customerId: customerId,
                    visitorId: visitorId,
                    message: message,
                    event: EventType.markAsRead,
                    config: config,
                    jwt: jwt
                )

                self.networkClient?.perform(request) { result in
                    switch result {
                    case .success:
                        DispatchQueue.main.async {
                            completion(.success)
                        }

                    case .failure(let error):
                        self.handleRequestError(error)
                        DispatchQueue.main.async {
                            completion(.error(.errorSendingRequest))
                        }
                    }
                }

            } catch {
                self.handleRequestError(error)
                DispatchQueue.main.async {
                    completion(.error(.errorSendingRequest))
                }
            }
        }, onFailure: { _ in
            DispatchQueue.main.async {
                completion(.error(.errorSendingRequest))
            }
        })
    }
    
    /// Updates the read status of the given message on the server.
    ///
    /// - Parameters:
    ///   - message: The message to update.
    ///   - isRead: The new read status of the message.
    /// - Returns: A promise indicating the completion of the read status update.
    // MARK: - Set UnRead Async
    public func setAsUnReadAsync(
        message: EmbeddedMessage,
        isRead: Bool = false,
        completion: @escaping EmbeddedMessagingGetHandler
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

        resolveJWT(userId: customerId, action: { [weak self] jwt in
            guard let self = self else { return }
            do {
                let request = try self.createReportEventRequest(
                    customerId: customerId,
                    visitorId: visitorId,
                    message: message,
                    event: EventType.markAsUnread,
                    config: config,
                    jwt: jwt
                )

                self.networkClient?.perform(request) { result in
                    switch result {
                    case .success:
                        DispatchQueue.main.async {
                            completion(.success)
                        }

                    case .failure(let error):
                        self.handleRequestError(error)
                        DispatchQueue.main.async {
                            completion(.error(.errorSendingRequest))
                        }
                    }
                }

            } catch {
                self.handleRequestError(error)
                DispatchQueue.main.async {
                    completion(.error(.errorSendingRequest))
                }
            }
        }, onFailure: { _ in
            DispatchQueue.main.async {
                completion(.error(.errorSendingRequest))
            }
        })
    }
    
    /// Reports a click metric for the given message.
    ///
    /// - Parameter message: The message to report the click metric for.
    /// - Returns: A promise indicating the completion of the click metric report.
    // MARK: - Report Click metric Async
    public func reportClickMetricAsync(
        message: EmbeddedMessage,
        completion: @escaping EmbeddedMessagingGetHandler
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

        resolveJWT(userId: customerId, action: { [weak self] jwt in
            guard let self = self else { return }
            do {
                let request = try self.createReportEventRequest(
                    customerId: customerId,
                    visitorId: visitorId,
                    message: message,
                    event: EventType.clickMetric,
                    config: config,
                    jwt: jwt
                )

                self.networkClient?.perform(request) { result in
                    switch result {
                    case .success:
                        DispatchQueue.main.async {
                            completion(.success)
                        }

                    case .failure(let error):
                        self.handleRequestError(error)
                        DispatchQueue.main.async {
                            completion(.error(.errorSendingRequest))
                        }
                    }
                }

            } catch {
                self.handleRequestError(error)
                DispatchQueue.main.async {
                    completion(.error(.errorSendingRequest))
                }
            }
        }, onFailure: { _ in
            DispatchQueue.main.async {
                completion(.error(.errorSendingRequest))
            }
        })
    }
    
    
    // MARK: - Create Get Messages Request
    private func createGetEmbeddedMessagesRequest(
        customerId: String,
        visitorId: String,
        config: EmbeddedMessagingConfig,
        containers: [ContainerRequestOptions]? = nil,
        jwt: String? = nil
    ) throws -> NetworkRequest {
        
        let (region, brandId, tenantId) = getConfigValues(from: config)
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "CustomerId", value: customerId),
            URLQueryItem(name: "VisitorId", value: visitorId),
            URLQueryItem(name: "TenantId", value: tenantId),
            URLQueryItem(name: "BrandId", value: brandId)
        ]
        
        let baseURL = URL(string: "https://optimobile-inbox-srv-\(region).optimove.net")!
        let path = "/api/v2/embedded-messages/get"

        let encoder = JSONEncoder()
        let bodyData = try encoder.encode(containers)

        var headers: [HTTPHeader] = [
            HTTPHeader(field: .contentType, value: .json)
        ]
        if let jwt = jwt {
            headers.append(HTTPHeader(field: .userJwt, value: jwt))
        }

        return NetworkRequest(
            method: .post,
            baseURL: baseURL,
            path: path,
            headers: headers,
            queryItems: queryItems,
            httpBody: bodyData
        )
    }

    
    // MARK: - Report Event
    private func createReportEventRequest(
        customerId: String,
        visitorId: String,
        message: EmbeddedMessage,
        event: EventType,
        config: EmbeddedMessagingConfig,
        jwt: String? = nil
    ) throws -> NetworkRequest {
        
        let (region, brandId, tenantId) = getConfigValues(from: config)
        let baseURL = URL(string: "https://optimobile-inbox-srv-\(region).optimove.net")!
        let path = "/api/v2/events/report"
        
        // Headers
        var headers: [HTTPHeader] = [
            HTTPHeader(field: .contentType, value: .json),
            HTTPHeader(field: .tenantId, value: .tenantId(id: tenantId))
        ]
        if let jwt = jwt {
            headers.append(HTTPHeader(field: .userJwt, value: jwt))
        }
        
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "TenantId", value: tenantId),
            URLQueryItem(name: "BrandId", value: brandId)
        ]
        // Prepare the body
        let isoDate = ISO8601DateFormatter().string(from: Date())
        let eventBody = [EventBody(
            timestamp: isoDate,
            uuid: UUID().uuidString,
            eventType: event.rawValue,
            customerId: customerId,
            visitorId: visitorId,
            context: [
                "messageId": message.id,
                "containerId": message.containerId ?? ""  // provide a default non-nil string
            ]
        )]

        let bodyData = try JSONEncoder().encode(eventBody)

        return NetworkRequest(
            method: .post,
            baseURL: baseURL,
            path: path,
            headers: headers,
            queryItems: queryItems,
            httpBody: bodyData
        )
    }
    
    
    // MARK: - Auth Helper

    /// Resolves a JWT if auth is configured, then calls `action`.
    /// If auth is not configured, calls `action(nil)` (proceed without JWT).
    /// If auth is configured but the token fetch fails, calls `onFailure` (fail-closed).
    private func resolveJWT(
        userId: String,
        action: @escaping (_ jwt: String?) -> Void,
        onFailure: @escaping (_ error: Swift.Error) -> Void
    ) {
        guard let authManager = authManager else {
            action(nil)
            return
        }
        authManager.getToken(userId: userId) { result in
            switch result {
            case .success(let jwt):
                action(jwt)
            case .failure(let error):
                Logger.error("Auth token fetch failed for EmbeddedMessaging: \(error.localizedDescription). Dropping request.")
                onFailure(error)
            }
        }
    }

    // MARK: - Log Failed Response
    private func logFailedResponse(_ error: Swift.Error) {
        Logger.error("Request failed: \(error.localizedDescription)")
    }
    
    
}
