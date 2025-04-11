import OptimoveCore
import Foundation

// Define a public class
public class EmbeddedMessagesService {

    // Define the method to create and send the network request
    public static func GetEmbeddedMessagesRequest(
        customerId: String,
        visitorId: String,
        tenantId: String,
        brandId: String,
        region: String,
        bodyData: [[String: Any]]? = nil,  // Optional body data
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        // Construct the base URL with the dynamic region
        let baseURL = URL(string: "https://optimobile-inbox-srv-\(region).optimove.net")!
        
        // Construct the path
        let path = "/api/v1/embeddedmessages/getembeddedmessages"
        
        // Construct the query items with parameters
        let queryItems = [
            URLQueryItem(name: "CustomerId", value: customerId),
            URLQueryItem(name: "VisitorId", value: visitorId),
            URLQueryItem(name: "TenantId", value: tenantId),
            URLQueryItem(name: "BrandId", value: brandId)
        ]
        
        // Create the full URL by appending the query items to the base URL and path
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = queryItems
        
        // Log the final URL
        print("Final Request URL: \(urlComponents.url!)")
        
        // Serialize bodyData into JSON
        let body: Data? = try? JSONSerialization.data(withJSONObject: bodyData as Any, options: [])
        
        // Construct the URLRequest
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.httpBody = body
        
        // Send the network request asynchronously using URLSession
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            // Handle the response asynchronously
            if let error = error {
                // Return the error if there was a problem with the request
                completion(.failure(error))
                return
            }
            
            // Check if the response is valid and data is available
            if let data = data {
                // Return the data as a success result
                completion(.success(data))
            } else {
                // If no data, return a custom error
                let noDataError = NSError(domain: "EmbeddedMessagesService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data returned from the server."])
                completion(.failure(noDataError))
            }
        }.resume()  // Start the network task
    }
    
    public static func DeleteEmbeddedMessageRequest(
        messageId: String,
        tenantId: String,
        brandId: String,
        region: String,
        completion: @escaping (Result<Data, Error>) -> Void  // Completion handler to return the result
    ) {
        // Construct the base URL with the dynamic region
        let baseURL = URL(string: "https://optimobile-inbox-srv-\(region).optimove.net")!
        
        // Construct the path, including the messageId directly in the URL
        let path = "/api/v1/messages/\(messageId)"
        
        // Construct the query items with parameters
        let queryItems = [
            URLQueryItem(name: "TenantId", value: tenantId),
            URLQueryItem(name: "BrandId", value: brandId)
        ]
        
        // Create the full URL by appending the query items to the base URL and path
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = queryItems
        
        // Construct the URLRequest
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = "DELETE"  // Use DELETE method instead of POST for deleting
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // Send the network request asynchronously using URLSession
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            // Handle the response asynchronously
            if let error = error {
                // Return the error if there was a problem with the request
                completion(.failure(error))
                return
            }
            
            // Check if the response is valid and data is available
            if let data = data {
                // Return the data as a success result
                completion(.success(data))
            } else {
                // If no data, return a custom error
                let noDataError = NSError(domain: "EmbeddedMessagesService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data returned from the server."])
                completion(.failure(noDataError))
            }
        }.resume()  // Start the network task
    }
}
