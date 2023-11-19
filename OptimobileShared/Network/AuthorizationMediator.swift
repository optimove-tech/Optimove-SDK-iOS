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

final class AuthorizationMediator {
    var basicAuthorization: String?
    let storage: KeyValPersistenceHelper.Type
    
    init(basicAuthorization: String? = nil, storage: KeyValPersistenceHelper.Type) {
        self.basicAuthorization = basicAuthorization
        self.storage = storage
    }
    
    func readCredentialsFromStorage() -> Credentials? {
        guard let data = storage.object(forKey: OptimobileUserDefaultsKey.CREDENTIALS_JSON.rawValue) as? Data else {
            return nil
        }
        return try? JSONDecoder().decode(Credentials.self, from: data)
    }
    
    func getBasicAuthorization() throws -> String {
        if basicAuthorization == nil, let credentials = readCredentialsFromStorage() {
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
