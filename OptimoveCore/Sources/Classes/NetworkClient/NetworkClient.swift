//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public typealias NetworkServiceCompletion = (Result<NetworkResponse<Data?>, NetworkError>) -> Void

public protocol NetworkClient {
    func perform(_ request: NetworkRequest, _ completion: @escaping NetworkServiceCompletion)
}

public struct NetworkClientImpl {

    let session: URLSession

    public init(configuration: URLSessionConfiguration = URLSessionConfiguration.default) {
        session = URLSession(configuration: configuration)
    }

}

extension NetworkClientImpl: NetworkClient {

    public func perform(_ request: NetworkRequest, _ completion: @escaping NetworkServiceCompletion) {

        let baseURL: URL = request.baseURL

        var urlComponents = URLComponents()
        urlComponents.scheme = baseURL.scheme
        urlComponents.host = baseURL.host
        urlComponents.path = baseURL.path
        urlComponents.queryItems = request.queryItems

        let buildURL: () -> URL? = {
            if let path = request.path {
                guard let url = urlComponents.url?.appendingPathComponent(path) else {
                    return nil
                }
                return url
            } else {
                return urlComponents.url
            }
        }

        guard let url = buildURL() else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.httpBody
        urlRequest.timeoutInterval = request.timeoutInterval

        request.headers?.forEach { urlRequest.addValue($0.value, forHTTPHeaderField: $0.field) }

        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                completion(.failure(NetworkError.error(error)))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.requestFailed))
                return
            }
            if (200...299).contains(httpResponse.statusCode) {
                completion(.success(NetworkResponse<Data?>(statusCode: httpResponse.statusCode, body: data)))
            }
            if (400...499).contains(httpResponse.statusCode) {
                completion(.failure(NetworkError.requestInvalid(data)))
            }

        }
        task.resume()
    }

}
