//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public final class NetworkRequest {

    public struct DefaultValue {
        public static let path: String? = nil
        public static let headers: [HTTPHeader] = []
        public static let queryItems: [URLQueryItem]? = nil
        public static let httpBody: Data? = nil
        public static let timeoutInterval: TimeInterval = 60
    }

    public let method: HTTPMethod
    public let baseURL: URL
    public let path: String?
    public let headers: [HTTPHeader]?
    public let queryItems: [URLQueryItem]?
    public let httpBody: Data?
    public let timeoutInterval: TimeInterval

    public required init(
        method: HTTPMethod,
        baseURL: URL,
        path: String? = DefaultValue.path,
        headers: [HTTPHeader] = DefaultValue.headers,
        queryItems: [URLQueryItem]? = DefaultValue.queryItems,
        httpBody: Data? = DefaultValue.httpBody,
        timeoutInterval: TimeInterval = DefaultValue.timeoutInterval) {
        self.method = method
        self.baseURL = baseURL
        self.path = path
        self.headers = headers
        self.queryItems = queryItems
        self.httpBody = httpBody
        self.timeoutInterval = timeoutInterval
    }

    public convenience init<Body: Encodable>(
        method: HTTPMethod,
        baseURL: URL,
        path: String? = DefaultValue.path,
        headers: [HTTPHeader] = DefaultValue.headers,
        queryItems: [URLQueryItem]? = DefaultValue.queryItems,
        body: Body,
        timeoutInterval: TimeInterval = DefaultValue.timeoutInterval) throws {
        self.init(
            method: method,
            baseURL: baseURL,
            path: path,
            headers: headers + [HTTPHeader(field: .contentType, value: .json)],
            queryItems: queryItems,
            httpBody: try JSONEncoder().encode(body),
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
    let field: String
    let value: String
}

public extension HTTPHeader {

    enum Fields: String {
        case contentType = "Content-Type"
        case userAgent = "User-Agent"
    }

    enum Values: String {
        case json = "application/json"
    }

}

extension HTTPHeader {

    public init(field: Fields, value: Values) {
        self.field = field.rawValue
        self.value = value.rawValue
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
        [Headers]: \(String(describing: headers.map { $0.description }))
        [QueryItems]: \(String(describing: queryItems.map { $0.description }))
        [Body]: \(String(describing: httpBody == nil ? nil : String(data: httpBody!, encoding: .utf8)))
        [TimeoutInterval]: \(timeoutInterval)
        """
    }
}
