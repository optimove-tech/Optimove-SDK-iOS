//  Copyright © 2023 Optimove. All rights reserved.

import Foundation

protocol AuthorizationMediatorProtocol {
    func getAuthHeader() -> String?
    func setBasicAuth(user: String, password: String)
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
}

extension AuthorizationMediator: AuthorizationMediatorProtocol {
    func getAuthHeader() -> String? {
        return basicAuthorization
    }

    func setBasicAuth(user: String, password: String) {
        let creds = "\(user):\(password)"
        if let token = creds.data(using: .utf8)?.base64EncodedString() {
            basicAuthorization = "Basic \(token)"
        }
    }
}

extension AuthorizationMediator: HttpAuthorizationProtocol {
    static let field = "Authorization"

    func authorizeRequest(_ urlRequest: inout URLRequest) throws {
        if basicAuthorization == nil, let credentials = readCredentialsFromStorage() {
            setBasicAuth(user: credentials.apiKey, password: credentials.secretKey)
        }
        guard let basicAuthorization else {
            throw HttpAuthorizationError.missingAuthHeader
        }
        urlRequest.addValue(basicAuthorization, forHTTPHeaderField: AuthorizationMediator.field)
    }
}
