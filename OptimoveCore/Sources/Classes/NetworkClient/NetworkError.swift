//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public enum NetworkError: LocalizedError {
    case error(Error)
    case noData
    case invalidURL
    case authFailed(Error)
    case unauthorized(Data?)
    /// Backend returned 401 but no AuthManager is configured — will never produce a JWT.
    case authNotConfigured
    case requestInvalid(Data?)
    case requestFailed

    public var errorDescription: String? {
        return "NetworkError: " + {
            switch self {
            case let .error(error):
                return "'\(error.localizedDescription)'"
            case .noData:
                return "No data returns."
            case .invalidURL:
                return "Invalid URL."
            case let .authFailed(error):
                return "Auth token fetch failed: \(error.localizedDescription)"
            case let .unauthorized(data):
                var msg = "Unauthorized (401)."
                if let data = data, let string = String(bytes: data, encoding: .utf8) {
                    msg = msg + "\n\(string)"
                }
                return msg
            case .authNotConfigured:
                return "Backend requires authentication but enableAuth() was not configured."
            case let .requestInvalid(data):
                var msg = "Invalid resquest."
                if let data = data, let string = String(bytes: data, encoding: .utf8) {
                    msg = msg + "\n\(string)"
                }
                return msg
            case .requestFailed:
                return "Request failed."
            }
        }()
    }
}
