//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

/// Return a non-nil generic type or throw an error. A type will be defined by type inference. Using for simplifying unwrap and cast procedures.
///
/// - Parameter raw: Any optional type.
/// - Returns: Generic non-nil type
/// - Throws: CastError
public func cast<T>(_ raw: Any?, _ function: String = #function, _ line: Int = #line) throws -> T {
    let unwrapped = try unwrap(raw)
    guard let value = unwrapped as? T else {
        throw CastError.unableCast(value: unwrapped, expectedType: T.self, function: function, line: line)
    }
    return value
}

/// Return a non-nil generic type or throw an error. A type will be defined by type inference. Using for simplifying unwrap procedure.
///
/// - Parameter
///   - raw: Generic optional type.
/// - Returns: Generic non-nil type
/// - Throws: CastError
public func unwrap<T>(_ raw: T?, _ function: String = #function, _ line: Int = #line) throws -> T {
    return try unwrap(raw, error: nil, function, line)
}

/// Return a non-nil generic type or throw an error. A type will be defined by type inference. Using for simplifying unwrap procedure.
///
/// - Parameter
///   - raw: Generic optional type.raw: Generic optional type.
///   - error: An error that will be throw instead of `CastError`
/// - Returns: Generic non-nil type
/// - Throws: CastError

public func unwrap<T>(_ raw: T?, error: Error?, _ function: String = #function, _ line: Int = #line) throws -> T {
    guard let unwrapped = raw else {
        throw error ?? CastError.failedToUnwrap(value: raw, expectedType: T.self, function: function, line: line)
    }
    return unwrapped
}

public enum CastError: LocalizedError {
    case failedToUnwrap(value: Any?, expectedType: Any.Type, function: String, line: Int)
    case unableCast(value: Any, expectedType: Any.Type, function: String, line: Int)

    public var errorDescription: String? {
        switch self {
        case let .failedToUnwrap(value, expectedType, function, line):
            return """
            Failed to unwrapping value: \(value ?? "nil")
            with expected type: \(expectedType)
            at function: \(function):\(line)
            """
        case let .unableCast(value, expectedType, function, line):
            return """
            Unable cast value: \(value)
            to type: \(expectedType)
            at function: \(function):\(line)
            """
        }
    }
}

public enum GuardError: LocalizedError {
    case custom(String)

    public var errorDescription: String? {
        switch self {
        case let .custom(message):
            return message
        }
    }
}

public let tryCatch: (() throws -> Void) -> Void = { function in
    {
        do {
            try function()
        } catch {
            Logger.error(error.localizedDescription)
        }
    }()
}
