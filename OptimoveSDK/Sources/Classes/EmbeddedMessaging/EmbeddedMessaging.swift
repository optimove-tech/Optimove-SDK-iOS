import OptimoveCore
import Foundation

public class EmbeddedMessagesService {
    
    private static var instance: EmbeddedMessagesService?
    
    public enum Error: LocalizedError {
        case alreadyInitialized
        case notInitialized
        case configurationIsMissing

        public var errorDescription: String? {
            switch self {
            case .alreadyInitialized:
                return "The PreferenceCenterSDK has already been initialized."
            case .notInitialized:
                return "Preference center has not been initialized."
            case .configurationIsMissing:
                return "Preference center configuration is missing, but the feature was requested. Please provide valid credentials."
            }
        }
    }
    
    static func initialize(with optimoveConfig: OptimoveConfig, storage: OptimoveStorage, networkClient: NetworkClient) throws {
        if instance !== nil, optimoveConfig.features.contains(.delayedConfiguration) {
            if optimoveConfig.getEmbeddedMessagingConfig() == nil {
                throw Error.configurationIsMissing
            }
            return
        }

        if instance != nil {
            assertionFailure(Error.alreadyInitialized.localizedDescription)
            throw Error.alreadyInitialized
        }
    }

    private func getConfigValues(from config: EmbeddedMessagingConfig) -> (region: String, brandGroupId: String, tenantId: String) {
        let region = config.region
        let brandGroupId = config.brandId
        let tenantId = config.tenantId.description
        return (region, brandGroupId, tenantId)
    }
    
    static var isSdkRunning: Bool {
        return Optimove.getConfig()?.getPreferenceCenterConfig() != nil
    }

    public static func getEmbeddedMessagesAsync(
        customerId: String,
        visitorId: String,
        tenantId: String,
        brandId: String,
        region: String,
        bodyData: [[String: Any]]? = nil,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        let baseURL = URL(string: "https://optimobile-inbox-srv-\(region).optimove.net")!
        let path = "/api/v1/embeddedmessages/getembeddedmessages"
        
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [
            URLQueryItem(name: "CustomerId", value: customerId),
            URLQueryItem(name: "VisitorId", value: visitorId),
            URLQueryItem(name: "TenantId", value: tenantId),
            URLQueryItem(name: "BrandId", value: brandId)
        ]
        
        let finalURL = urlComponents.url!
        print("Final Request URL: \(finalURL)")
        
        let body: Data?
        do {
            if let bodyData = bodyData {
                body = try JSONSerialization.data(withJSONObject: bodyData, options: [])
            } else {
                body = nil
            }
        } catch {
            completion(.failure(.configurationIsMissing))
            return
        }

        var urlRequest = URLRequest(url: finalURL)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.httpBody = body
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(.configurationIsMissing))
                return
            }

            if let data = data {
                completion(.success(data))
            } else {
                completion(.failure(.configurationIsMissing))
            }
        }.resume()
    }

    public static func deleteMessageAsync(
        messageId: String,
        tenantId: String,
        brandId: String,
        region: String,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        let baseURL = URL(string: "https://optimobile-inbox-srv-\(region).optimove.net")!
        let path = "/api/v1/messages/\(messageId)"
        
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = [
            URLQueryItem(name: "TenantId", value: tenantId),
            URLQueryItem(name: "BrandId", value: brandId)
        ]
        
        let finalURL = urlComponents.url!
        
        var urlRequest = URLRequest(url: finalURL)
        urlRequest.httpMethod = "DELETE"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(.configurationIsMissing))
                return
            }

            if let data = data {
                completion(.success(data))
            } else {
                completion(.failure(.configurationIsMissing))
            }
        }.resume()
    }
}
