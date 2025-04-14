import OptimoveCore
import Foundation

public class EmbeddedMessagesService {
    
    private static var instance: EmbeddedMessagesService?
    private var storage: OptimoveStorage?
    private var networkClient: NetworkClient?


    
    public enum Error: LocalizedError {
        case alreadyInitialized
        case notInitialized
        case configurationIsMissing

        public var errorDescription: String? {
            switch self {
            case .alreadyInitialized:
                return "The EmbeddedMessagingSDK has already been initialized."
            case .notInitialized:
                return "Embedded messaging has not been initialized."
            case .configurationIsMissing:
                return "Embedded messaging configuration is missing, but the feature was requested. Please provide valid credentials."
            }
        }
    }
    
    public enum ResultType {
        case success
        case errorUserNotSet
        case errorCredentialsNotSet
        case error
    }
    
    public enum CampaignKind: Int {
        case push = 0
        case inApp = 1
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
    
    public typealias EmbeddedMessagingGetHandler = (Result<Data, Error>) -> Void
    public typealias EmbeddedMessagingSetHandler = (Result<Data, Error>) -> Void

    private func getConfigValues(from config: EmbeddedMessagingConfig) -> (region: String, brandGroupId: String, tenantId: String) {
        let region = config.region
        let brandGroupId = config.brandId
        let tenantId = config.tenantId.description
//        return (region, brandGroupId, tenantId)
        return ("dev", "9abb8d6d-62ed-42d1-97d1-c82d15f9c1fc", "3013")
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
    
    public static func setReadAsync(from message: EmbeddedMessage) {
           guard let url = URL(string: "https://optimobile-inbox-srv-dev.optimove.net/api/v1/messages/status") else {
               print("Invalid URL")
               return
           }
           
           let brandId = "9abb8d6d-62ed-42d1-97d1-c82d15f9c1fc"
           let tenantId = "3013"
           
           // Parse readAt to Int64 from string
           let readAtMillis: Int64? = {
               if let readAtStr = message.readAt, let millis = Int64(readAtStr) {
                   return millis
               }
               return nil
           }()
           
           guard let readAt = readAtMillis else {
               print("Invalid or missing readAt value")
               return
           }
           
           let statusMetric: [String: Any] = [
               "messageId": message.id,
               "engagementId": message.engagementId,
               "executionDateTime": message.executionDateTime,
               "campaignKind": message.campaignKind,
               "customerId": message.customerId,
               "readAt": readAt
           ]
           
           let body: [String: Any] = [
               "brandId": brandId,
               "tenantId": tenantId,
               "statusMetrics": [statusMetric]
           ]
           
           var request = URLRequest(url: url)
           request.httpMethod = "PUT"
           request.setValue("application/json", forHTTPHeaderField: "Content-Type")
           
           do {
               request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
           } catch {
               print("Failed to serialize JSON body: \(error)")
               return
           }
           
           let task = URLSession.shared.dataTask(with: request) { data, response, error in
               if let error = error {
                   print("Request failed: \(error)")
                   return
               }
               
               if let httpResponse = response as? HTTPURLResponse {
                   print("Response status code: \(httpResponse.statusCode)")
               }
               
               if let data = data, let responseText = String(data: data, encoding: .utf8) {
                   print("Response body: \(responseText)")
               }
           }
           
           task.resume()
       }
   }
    
    
    
    
    private func logFailedResponse(_ error: Swift.Error) {
        Logger.error("Request failed with error: \(error.localizedDescription)")
    }

