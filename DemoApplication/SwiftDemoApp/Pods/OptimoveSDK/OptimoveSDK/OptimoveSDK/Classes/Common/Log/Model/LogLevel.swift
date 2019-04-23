//
//  LogLevel.swift
//  OptimoveSDK

import Foundation

@objc public enum LogLevel: Int, Codable, Comparable {

    case debug
    case info
    case warn
    case error

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

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    } 
}
