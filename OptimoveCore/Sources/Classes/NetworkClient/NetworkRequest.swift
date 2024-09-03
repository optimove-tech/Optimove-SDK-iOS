//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public final class NetworkRequest {
    public enum DefaultValue {
        public static let path: String? = nil
        public static let headers: [HTTPHeader] = []
        public static let queryItems: [URLQueryItem]? = nil
        public static let httpBody: Data? = nil
        public static let timeoutInterval: TimeInterval = 60
        public static let keyEncodingStrategy: KeyEncodingStrategy = .useDefaultKeys
    }

    public let method: HTTPMethod
    public let baseURL: URL
    public let path: String?
    public let headers: [HTTPHeader]?
    public let queryItems: [URLQueryItem]?
    public let httpBody: Data?
    public let timeoutInterval: TimeInterval
    public let keyEncodingStrategy: KeyEncodingStrategy

    public required init(
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

    public convenience init<Body: Encodable>(
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

public enum HTTPMethod: String {
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

public struct HTTPHeader {
    public let field: String
    public let value: String
}

public extension HTTPHeader {
    enum Fields: String {
        case contentType = "Content-Type"
        case userAgent = "User-Agent"
        case tenantId = "X-Tenant-Id"
        case accept
    }

    enum Values: CustomStringConvertible {
        case json
        case tenantId(id: String)
        case textplain

        public var description: String {
            switch self {
            case .json:
                return "application/json"
            case .tenantId(let id):
                return id
            case .textplain:
                return "text/plain"
            }
        }
    }
}

public extension HTTPHeader {
    init(field: Fields, value: Values) {
        self.field = field.rawValue
        self.value = String(describing: value) 
    }
}

extension HTTPHeader: CustomStringConvertible {
    public var description: String {
        return "key: \(field), value: \(value)"
    }
}

extension NetworkRequest: CustomStringConvertible {
    public var description: String {
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

public enum KeyEncodingStrategy {
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
