//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

final class NetworkRequest {
    enum DefaultValue {
        static let path: String? = nil
        static let headers: [HTTPHeader] = []
        static let queryItems: [URLQueryItem]? = nil
        static let httpBody: Data? = nil
        static let timeoutInterval: TimeInterval = 60
        static let keyEncodingStrategy: KeyEncodingStrategy = .useDefaultKeys
    }

    let method: HTTPMethod
    let baseURL: URL
    let path: String?
    let headers: [HTTPHeader]?
    let queryItems: [URLQueryItem]?
    let httpBody: Data?
    let timeoutInterval: TimeInterval
    let keyEncodingStrategy: KeyEncodingStrategy

    required init(
        method: HTTPMethod,
        baseURL: URL,
        path: String? = DefaultValue.path,
        headers: [HTTPHeader] = DefaultValue.headers,
        queryItems: [URLQueryItem]? = DefaultValue.queryItems,
        httpBody: Data? = DefaultValue.httpBody,
        timeoutInterval: TimeInterval = DefaultValue.timeoutInterval,
        keyEncodingStrategy: KeyEncodingStrategy = DefaultValue.keyEncodingStrategy
    ) {
        self.method = method
        self.baseURL = baseURL
        self.path = path
        self.headers = headers
        self.queryItems = queryItems
        self.httpBody = httpBody
        self.timeoutInterval = timeoutInterval
        self.keyEncodingStrategy = keyEncodingStrategy
    }

    convenience init<Body: Encodable>(
        method: HTTPMethod,
        baseURL: URL,
        path: String? = DefaultValue.path,
        headers: [HTTPHeader] = DefaultValue.headers,
        queryItems: [URLQueryItem]? = DefaultValue.queryItems,
        body: Body,
        timeoutInterval: TimeInterval = DefaultValue.timeoutInterval,
        keyEncodingStrategy: KeyEncodingStrategy = DefaultValue.keyEncodingStrategy
    ) throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = keyEncodingStrategy.toJSONEncoderStrategy()
        encoder.dateEncodingStrategy = .formatted(Formatter.iso8601withFractionalSeconds)
        try self.init(
            method: method,
            baseURL: baseURL,
            path: path,
            headers: headers + [HTTPHeader(field: .contentType, value: .json)],
            queryItems: queryItems,
            httpBody: encoder.encode(body),
            timeoutInterval: timeoutInterval
        )
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case put = "PUT"
    case post = "POST"
    case delete = "DELETE"
    case head = "HEAD"
    case options = "OPTIONS"
    case trace = "TRACE"
    case connect = "CONNECT"
    case patch = "PATCH"
}

struct HTTPHeader {
    let field: String
    let value: String
}

extension HTTPHeader {
    enum Fields: String {
        case contentType = "Content-Type"
        case userAgent = "User-Agent"
        case tenantId = "X-Tenant-Id"
        case accept
    }

   
    enum Values {
        case json
        case tenantId(id: String)
        case textplain

        var value: String {
            switch self {
            case .json:
                "application/json"
            case .tenantId(let id):
                id
            case .textplain:
                "text/plain"
            }
        }
    }
}

extension HTTPHeader {
    init(field: Fields, value: Values) {
        self.field = field.rawValue
        self.value = value.value
    }
}

extension HTTPHeader: CustomStringConvertible {
    var description: String {
        return "key: \(field), value: \(value)"
    }
}

extension NetworkRequest: CustomStringConvertible {
    var description: String {
        return """
        [Method]: \(method.rawValue)
        [URL]: \(baseURL.absoluteString)
        [Path]: \(String(describing: path))
        [Headers]: \(String(describing: headers.map(\.description)))
        [QueryItems]: \(String(describing: queryItems.map(\.description)))
        [Body]: \(String(describing: httpBody == nil ? nil : String(data: httpBody!, encoding: .utf8)))
        [TimeoutInterval]: \(timeoutInterval)
        """
    }
}

enum KeyEncodingStrategy {
    case useDefaultKeys
    case convertToSnakeCase
    case custom(([CodingKey]) -> CodingKey)

    func toJSONEncoderStrategy() -> JSONEncoder.KeyEncodingStrategy {
        switch self {
        case .convertToSnakeCase:
            return .convertToSnakeCase
        case .useDefaultKeys:
            return .useDefaultKeys
        case let .custom(function):
            return .custom(function)
        }
    }
}
