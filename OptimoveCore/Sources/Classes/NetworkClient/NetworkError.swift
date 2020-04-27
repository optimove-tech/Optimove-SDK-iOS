//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public enum NetworkError: LocalizedError {
    case error(Error)
    case noData
    case invalidURL
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
            case .requestFailed:
                return "Request failed."
            }
        }()
    }
}
