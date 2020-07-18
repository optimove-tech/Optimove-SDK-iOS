//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

enum CastError: LocalizedError {
    case failedToUnwrap(value: Any?, expectedType: Any.Type)
    case unableCast(value: Any, expectedType: Any.Type)
    case customMessage(message: String)

    var errorDescription: String? {
        switch self {
        case let .failedToUnwrap(value, expectedType):
            return "Failed to unwrapping value: '\(value ?? "nil")', with expected type: '\(expectedType)'"
        case let .unableCast(value, expectedType):
            return "Unable cast value: '\(value)', to type: '\(expectedType)'"
        case let .customMessage(message):
            return message
        }
    }

}

/// Return a non-nil generic type or throw an error. A type will be defined by type inference. Using for simplifying unwrap and cast procedures.
///
/// - Parameter raw: Any optional type.
/// - Returns: Generic non-nil type
/// - Throws: CastError
func cast<T>(_ raw: Any?) throws -> T {
    return try customCast(raw, nil)
}

func customCast<T>(_ raw: Any?, _ error: CastError? = nil) throws -> T {
    let unwrapped = try unwrap(raw)
    guard let value = unwrapped as? T else {
        throw error ?? CastError.unableCast(value: unwrapped, expectedType: T.self)
    }
    return value
}

/// Return a non-nil generic type or throw an error. A type will be defined by type inference. Using for simplifying unwrap procedure.
///
/// - Parameter raw: Generic optional type.
/// - Returns: Generic non-nil type
/// - Throws: CastError
func unwrap<T>(_ raw: T?) throws -> T {
    return try customUnwrap(raw, nil)
}

func customUnwrap<T>(_ raw: T?, _ error: CastError? = nil) throws -> T {
    guard let unwrapped = raw else {
        throw error ?? CastError.failedToUnwrap(value: raw, expectedType: T.self)
    }
    return unwrapped
}
