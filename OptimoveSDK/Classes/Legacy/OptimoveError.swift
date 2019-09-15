//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public enum OptimoveError: LocalizedError, Equatable {
    case error(String)
    case noStatusCode
    case statusCodeInvalid
    case invalidEvent
    case illegalParameterLength
    case mismatchParamterType
    case mandatoryParameterMissing
    case emptyData
    case badRequest
    case notFound
    case gone
    case responseError(Response)

    public var errorDescription: String? {
        switch self {
        case let .error(string):
            return string
        case .noStatusCode:
            return "noStatusCode"
        case .statusCodeInvalid:
            return "statusCodeInvalid"
        case .invalidEvent:
            return "invalidEvent"
        case .illegalParameterLength:
            return "illegalParameterLength"
        case .mismatchParamterType:
            return "mismatchParamterType"
        case .mandatoryParameterMissing:
            return "mandatoryParameterMissing"
        case .emptyData:
            return "emptyData"
        case .badRequest:
            return "badRequest"
        case .notFound:
            return "notFound"
        case .gone:
            return "gone"
        case let .responseError(response):
            return "responseError: \(String(describing: response.errorDescription))"
        }
    }
}

public extension OptimoveError {
    enum Response: LocalizedError {
        case noData

        public var errorDescription: String? {
            switch self {
            case .noData:
                return "noData"
            }
        }
    }
}
