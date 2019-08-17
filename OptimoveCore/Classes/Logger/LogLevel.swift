//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

@objc public enum LogLevel: Int  {

    case debug = 0
    case info = 1
    case warn = 2
    case error = 3

    init?(string: String) {
        switch string {
        case CodingKeys.debug.rawValue:
            self = .debug
        case CodingKeys.info.rawValue:
            self = .info
        case CodingKeys.warn.rawValue:
            self = .warn
        case CodingKeys.error.rawValue:
            self = .error
        default:
            return nil
        }
    }

}

extension LogLevel: Comparable {

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

extension LogLevel: Codable {

    enum CodingKeys: String, CodingKey {
        case debug
        case info
        case warn
        case error
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .debug: try container.encode(CodingKeys.debug.rawValue)
        case .info: try container.encode(CodingKeys.info.rawValue)
        case .warn: try container.encode(CodingKeys.warn.rawValue)
        case .error: try container.encode(CodingKeys.error.rawValue)
        }
    }
}
