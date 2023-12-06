//  Copyright © 2022 Optimove. All rights reserved.

import Foundation

enum KSHttpError: Error {
    case responseCastingError
    case badStatusCode
}

typealias KSHttpSuccessBlock = (_ response: HTTPURLResponse?, _ decodedBody: Any?) -> Void
typealias KSHttpFailureBlock = (_ response: HTTPURLResponse?, _ error: Error?, _ decodedBody: Any?) -> Void

enum KSHttpDataFormat {
    case json
    case plist
    case rawData
}

enum KSHttpMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
}

final class KSHttpClient {
    private let serviceType: UrlBuilder.Service
    private let urlBuilder: UrlBuilder
    private let urlSession: URLSession
    private var authHeader: String?
    private let requestFormat: KSHttpDataFormat
    private let responseFormat: KSHttpDataFormat
    private let authorization: HttpAuthorizationProtocol

    // MARK: Initializers & Configs

    init(
        serviceType: UrlBuilder.Service,
        urlBuilder: UrlBuilder,
        requestFormat: KSHttpDataFormat,
        responseFormat: KSHttpDataFormat,
        authorization: HttpAuthorizationProtocol,
        additionalHeaders: [AnyHashable: Any]? = nil
    ) {
        self.authorization = authorization
        self.serviceType = serviceType
        self.urlBuilder = urlBuilder
        self.requestFormat = requestFormat
        self.responseFormat = responseFormat

        let config = URLSessionConfiguration.ephemeral

        if requestFormat == .json {
            config.httpAdditionalHeaders = ["Accept": "application/json"]
        }

        if additionalHeaders != nil {
            config.httpAdditionalHeaders = additionalHeaders
        }

        urlSession = URLSession(configuration: config)
        authHeader = nil
    }

    func invalidateSessionCancellingTasks(_ cancel: Bool) {
        if cancel {
            urlSession.invalidateAndCancel()
        } else {
            urlSession.finishTasksAndInvalidate()
        }
    }

    // MARK: HTTP Methods

    func sendRequest(_ method: KSHttpMethod, toPath path: String, data: Any?, onSuccess: @escaping KSHttpSuccessBlock, onFailure: @escaping KSHttpFailureBlock) {
        do {
            var request = try buildRequest(for: path, method: method, body: data)
            try authorization.authorizeRequest(&request, strategy: .basic)
            sendRequest(request: request, onSuccess: onSuccess, onFailure: onFailure)
        } catch {
            onFailure(nil, error, nil)
        }
    }

    // MARK: Helpers

    fileprivate func buildRequest(for path: String, method: KSHttpMethod, body: Any?) throws -> URLRequest {
        var url = try urlBuilder.urlForService(serviceType)

        // FIXME: The incoming path value contains not only path but also query parameters. This why we cannot append path component to the url. It will cause wrong encoding of the path component. The solution is to operate with URLComponents instead of path.
        url = URL(string: url.absoluteString.appending(path))!

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue

        switch requestFormat {
        case .json:
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        case .plist:
            break
        case .rawData:
            break
        }

        if let bodyVal = body {
            let encodedBody = encodeBody(bodyVal)
            urlRequest.httpBody = encodedBody
        }

        return urlRequest
    }

    fileprivate func encodeBody(_ body: Any) -> Data? {
        switch requestFormat {
        case .json:
            guard JSONSerialization.isValidJSONObject(body) else {
                print("Cannot serialize body to JSON")
                return nil
            }

            return try? JSONSerialization.data(withJSONObject: body, options: .init(rawValue: 0))
        case .rawData:
            guard let data = body as? Data else {
                print("Body not Data")
                return nil
            }
            return data
        default:
            print("No body encoder defined for format")
            return nil
        }
    }

    fileprivate func decodeBody(_ data: Data) -> Any? {
        if data.isEmpty {
            return nil
        }

        var decodedData: Any?

        switch responseFormat {
        case .json:
            decodedData = try? JSONSerialization.jsonObject(with: data, options: .init(rawValue: 0))
        case .plist:
            decodedData = try? PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil)
        case .rawData:
            decodedData = data
        }

        return decodedData
    }

    fileprivate func sendRequest(request: URLRequest, onSuccess: @escaping KSHttpSuccessBlock, onFailure: @escaping KSHttpFailureBlock) {
        let task = urlSession.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse else {
                onFailure(nil, KSHttpError.responseCastingError, nil)
                return
            }

            if error != nil {
                onFailure(httpResponse, error, nil)
                return
            }

            var decodedBody: Any?

            if let body = data {
                decodedBody = self.decodeBody(body)
            }

            if httpResponse.statusCode > 299 {
                onFailure(httpResponse, KSHttpError.badStatusCode, decodedBody)
                return
            }

            onSuccess(httpResponse, decodedBody)
        }

        task.resume()
    }
}

enum KSHttpUtil {
    static func urlEncode(_ url: String) -> String? {
        let unreserved = "-._~"
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: unreserved)

        let encoded = url.addingPercentEncoding(withAllowedCharacters: allowed)

        return encoded
    }
}
