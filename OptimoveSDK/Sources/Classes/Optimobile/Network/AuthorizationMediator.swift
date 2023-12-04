//  Copyright © 2023 Optimove. All rights reserved.

import Foundation

enum AuthorizationStrategy {
    case basic
    // case bearer
}

protocol AuthorizationMediatorProtocol {
    func getAuthorization(_: AuthorizationStrategy) throws -> String
}

enum HttpAuthorizationError: Error {
    case missingAuthHeader
}

protocol HttpAuthorizationProtocol {
    func authorizeRequest(_: inout URLRequest) throws
}

typealias CredentialsProvider = () -> OptimobileCredentials?

final class AuthorizationMediator {
    var basicAuthorization: String?
    let provider: CredentialsProvider

    init(basicAuthorization: String? = nil, provider: @escaping CredentialsProvider) {
        self.basicAuthorization = basicAuthorization
        self.provider = provider
    }

    func getBasicAuthorization() throws -> String {
        if basicAuthorization == nil, let credentials = provider() {
            setBasicAuth(user: credentials.apiKey, password: credentials.secretKey)
        }
        guard let basicAuthorization else {
            throw HttpAuthorizationError.missingAuthHeader
        }
        return basicAuthorization
    }

    func setBasicAuth(user: String, password: String) {
        let basic = "\(user):\(password)"
        if let token = basic.data(using: .utf8)?.base64EncodedString() {
            basicAuthorization = "Basic \(token)"
        }
    }
}

extension AuthorizationMediator: AuthorizationMediatorProtocol {
    func getAuthorization(_ strategy: AuthorizationStrategy) throws -> String {
        switch strategy {
        case .basic:
            return try getBasicAuthorization()
        }
    }
}

extension AuthorizationMediator: HttpAuthorizationProtocol {
    static let field = "Authorization"

    func authorizeRequest(_ urlRequest: inout URLRequest) throws {
        let basicAuthorization = try getAuthorization(.basic)
        urlRequest.addValue(basicAuthorization, forHTTPHeaderField: AuthorizationMediator.field)
    }
}
