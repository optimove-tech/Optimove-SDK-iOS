// Copiright 2019 Optimove

import Foundation

enum CastError: LocalizedError {
    case failedToUnwrap(value: Any?, expectedType: Any.Type)
    case unableCast(value: Any, expectedType: Any.Type)
    
    var errorDescription: String? {
        switch self {
        case .failedToUnwrap(let value, let expectedType):
            return "Failed to unwrapping value: '\(value ?? "nil")', with expected type: '\(expectedType)'"
        case .unableCast(let value, let expectedType):
            return "Unable cast value: '\(value)', to type: '\(expectedType)'"
        }
    }
    
}

/// Return a non-nil generic type or throw an error. A type will be defined by type inference. Using for simplifying unwrap and cast procedures.
///
/// - Parameter raw: Any optional type.
/// - Returns: Generic non-nil type
/// - Throws: CastError
func cast<T>(_ raw: Any?) throws -> T {
    let unwrapped = try unwrap(raw)
    guard let value = unwrapped as? T else {
        throw CastError.unableCast(value: unwrapped, expectedType: T.self)
    }
    return value
}

/// Return a non-nil generic type or throw an error. A type will be defined by type inference. Using for simplifying unwrap procedure.
///
/// - Parameter raw: Generic optional type.
/// - Returns: Generic non-nil type
/// - Throws: CastError
func unwrap<T>(_ raw: T?) throws -> T {
    guard let unwrapped = raw else {
        throw CastError.failedToUnwrap(value: raw, expectedType: T.self)
    }
    return unwrapped
}

