//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public enum NetworkError: LocalizedError {
    case error(Error)
    case noData
    case invalidURL
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
            case .requestInvalid(let data):
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
