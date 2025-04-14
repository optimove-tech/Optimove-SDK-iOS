import OptimoveCore
import Foundation

public class EmbeddedMessagesService {
    
    static func initialize(with optimoveConfig: OptimoveConfig, storage: OptimoveStorage, networkClient: NetworkClient) throws {
        if instance !== nil, optimoveConfig.features.contains(.delayedConfiguration) {
            guard optimoveConfig.getEmbeddedMessagingConfig() != nil else {
                throw Error.configurationIsMissing
            }
            return
        }

        guard instance == nil else {
            assertionFailure(Error.alreadyInitialized.localizedDescription)
            throw Error.alreadyInitialized
        }

        instance = EmbeddedMessagesService(storage: storage, networkClient: networkClient)
    }
    
    private func getConfigValues(from config: EmbeddedMessagingConfig) -> (region: String, brandGroupId: String, tenantId: String) {
        let region = config.region
        let brandGroupId = config.brandGroupId
        let tenantId = config.tenantId.description
        return (region, brandGroupId, tenantId)
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
        guard let baseURL = URL(string: "https://optimobile-inbox-srv-\(region).optimove.net") else {
            let error = NSError(domain: "EmbeddedMessagesService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid base URL."])
            completion(.failure(error))
            return
        }

        let path = "/api/v1/embeddedmessages/getembeddedmessages"
        
        let queryItems = [
            URLQueryItem(name: "CustomerId", value: customerId),
            URLQueryItem(name: "VisitorId", value: visitorId),
            URLQueryItem(name: "TenantId", value: tenantId),
            URLQueryItem(name: "BrandId", value: brandId)
        ]
        
        guard var urlComponents = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            let error = NSError(domain: "EmbeddedMessagesService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Unable to construct URL components."])
            completion(.failure(error))
            return
        }
        urlComponents.queryItems = queryItems
        
        guard let finalURL = urlComponents.url else {
            let error = NSError(domain: "EmbeddedMessagesService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Final URL could not be created."])
            completion(.failure(error))
            return
        }

        print("Final Request URL: \(finalURL)")
        
        let body: Data?
        do {
            if let bodyData = bodyData {
                body = try JSONSerialization.data(withJSONObject: bodyData, options: [])
            } else {
                body = nil
            }
        } catch {
            completion(.failure(error))
            return
        }

        var urlRequest = URLRequest(url: finalURL)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.httpBody = body
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let data = data {
                completion(.success(data))
            } else {
                let noDataError = NSError(domain: "EmbeddedMessagesService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data returned from the server."])
                completion(.failure(noDataError))
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
        guard let baseURL = URL(string: "https://optimobile-inbox-srv-\(region).optimove.net") else {
            let error = NSError(domain: "EmbeddedMessagesService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid base URL."])
            completion(.failure(error))
            return
        }

        let path = "/api/v1/messages/\(messageId)"
        
        let queryItems = [
            URLQueryItem(name: "TenantId", value: tenantId),
            URLQueryItem(name: "BrandId", value: brandId)
        ]
        
        guard var urlComponents = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            let error = NSError(domain: "EmbeddedMessagesService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Unable to construct URL components."])
            completion(.failure(error))
            return
        }
        urlComponents.queryItems = queryItems
        
        guard let finalURL = urlComponents.url else {
            let error = NSError(domain: "EmbeddedMessagesService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Final URL could not be created."])
            completion(.failure(error))
            return
        }

        var urlRequest = URLRequest(url: finalURL)
        urlRequest.httpMethod = "DELETE"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let data = data {
                completion(.success(data))
            } else {
                let noDataError = NSError(domain: "EmbeddedMessagesService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data returned from the server."])
                completion(.failure(noDataError))
            }
        }.resume()
    }
}
