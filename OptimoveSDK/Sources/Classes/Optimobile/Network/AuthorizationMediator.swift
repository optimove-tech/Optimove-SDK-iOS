//  Copyright © 2023 Optimove. All rights reserved.

import Foundation
import OptimobileCore

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

typealias HttpHeader = [String: String]

protocol HttpAuthorizationProtocol {
    func getAuthorizationHeader(strategy: AuthorizationStrategy) throws -> HttpHeader
}

typealias CredentialsProvider = () -> OptimobileCredentials?

final class AuthorizationMediator {
    var basicAuthorization: String?
    let provider: CredentialsProvider

    init(provider: @escaping CredentialsProvider) {
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
    static let HTTPHeaderField = "Authorization"

    func getAuthorizationHeader(strategy: AuthorizationStrategy) throws -> HttpHeader {
        return try [
            AuthorizationMediator.HTTPHeaderField: getAuthorization(strategy)
        ]
    }
}
