// Copiright 2019 Optimove

import Foundation

final class NetworkRequest {

    struct DefaultValue {
        static let path: String? = nil
        static let headers: [HTTPHeader] = []
        static let queryItems: [URLQueryItem]? = nil
        static let httpBody: Data? = nil
        static let timeoutInterval: TimeInterval = 60
    }

    let method: HTTPMethod
    let baseURL: URL
    let path: String?
    let headers: [HTTPHeader]?
    let queryItems: [URLQueryItem]?
    let httpBody: Data?
    let timeoutInterval: TimeInterval

    required init(
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

    convenience init<Body: Encodable>(
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

enum HTTPMethod: String {
    case get = "GET"
    case put = "PUT"
    case post = "POST"
    case delete = "DELETE"
    case head = "HEAD"
    case options = "OPTIONS"
    case trace = "TRACE"
    case connect = "CONNECT"
}

struct HTTPHeader {
    let field: String
    let value: String
}

extension HTTPHeader {

    enum Fields: String {
        case contentType = "Content-Type"
        case userAgent = "User-Agent"
    }

    enum Values: String {
        case json = "application/json"
    }

}

extension HTTPHeader {

    init(field: Fields, value: Values) {
        self.field = field.rawValue
        self.value = value.rawValue
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
        [Headers]: \(String(describing: headers.map { $0.description }))
        [QueryItems]: \(String(describing: queryItems.map { $0.description }))
        [Body]: \(String(describing: httpBody == nil ? nil : String(data: httpBody!, encoding: .utf8)))
        [TimeoutInterval]: \(timeoutInterval)
        """
    }
}
