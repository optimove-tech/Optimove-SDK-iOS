//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

@objc public enum LogLevel: Int, Codable, Comparable {

    case debug = 0
    case info = 1
    case warn = 2
    case error = 3

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

    public var name: String {
        switch self {
        case .debug: return "debug"
        case .info: return "info"
        case .warn: return "warn"
        case .error: return "error"
        }
    }

    init?(string: String) {
        switch string {
        case LogLevel.debug.name:
            self = .debug
        case LogLevel.info.name:
            self = .info
        case LogLevel.warn.name:
            self = .warn
        case LogLevel.error.name:
            self = .error
        default:
            return nil
        }
    }

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
