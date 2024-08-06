//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

typealias NetworkServiceCompletion = (Result<NetworkResponse<Data?>, NetworkError>) -> Void

extension NetworkClient {
    @available(iOS 13.0, *)
    func performAsync(_ request: NetworkRequest) async throws -> Data? {
        return try await withCheckedThrowingContinuation { continuation in
            perform(request) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response.body)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}


protocol NetworkClient {
    func perform(_ request: NetworkRequest, _ completion: @escaping NetworkServiceCompletion)
}

struct NetworkClientImpl {
    let session: URLSession

    init(configuration: URLSessionConfiguration = URLSessionConfiguration.default) {
        session = URLSession(configuration: configuration)
    }
}

extension NetworkClientImpl: NetworkClient {
    func perform(_ request: NetworkRequest, _ completion: @escaping NetworkServiceCompletion) {
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

        let task = session.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(NetworkError.error(error)))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.requestFailed))
                return
            }
            switch httpResponse.statusCode {
            case 200 ... 299:
                completion(.success(NetworkResponse<Data?>(statusCode: httpResponse.statusCode, body: data)))
            case 400 ... 499:
                completion(.failure(NetworkError.requestInvalid(data)))
            case 500 ... 599:
                completion(.failure(NetworkError.requestFailed))
            default:
                completion(.success(NetworkResponse<Data?>(statusCode: httpResponse.statusCode, body: data)))
            }
        }
        task.resume()
    }
}
