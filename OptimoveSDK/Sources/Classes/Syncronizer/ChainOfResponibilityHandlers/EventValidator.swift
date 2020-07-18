//  Copyright © 2017 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class EventValidator: Node {

    struct Constants {
        enum AllowedType: String, CaseIterable, RawRepresentable {
            case string = "String"
            case number = "Number"
            case boolean = "Boolean"

            init?(rawValue: String) {
                guard let type = AllowedType.allCases.first(where: { $0.rawValue == rawValue })
                    else { return nil }
                self = type
            }
        }
        static let legalParameterLength = 4_000
        static let legalUserIdLength = 200
    }

    private let configuration: Configuration
    private let storage: OptimoveStorage

    init(configuration: Configuration,
         storage: OptimoveStorage) {
        self.configuration = configuration
        self.storage = storage
    }

    override func execute(_ operation: CommonOperation) throws {
        let validationFunction = { [configuration] () -> CommonOperation in
            switch operation {
            case let .report(events: events):
                try events.forEach { event in
                    let eventConfig = try event.matchConfiguration(with: configuration.events)
                    try self.validate(event: event, withConfig: eventConfig)
                }
                return operation
            default:
                return operation
            }
        }
        try next?.execute(validationFunction())
    }

    private func validate(event: Event, withConfig eventConfiguration: EventsConfig) throws {
        var errors: [ValidatorError] = []

        /// Check the allowed number of parameters
        let numberOfParamaters = event.context.count
        let allowedNumberOfParameters = configuration.optitrack.maxActionCustomDimensions
        if numberOfParamaters > allowedNumberOfParameters {
            errors.append(
                ValidatorError.limitOfParameters(
                    name: event.name,
                    actual: numberOfParamaters,
                    limit: allowedNumberOfParameters
                )
            )
        }

        /// Verify mandatory parameters
        for (key, parameter) in eventConfiguration.parameters {
            guard event.context[key] == nil else {
                continue
            }
            /// Check has mandatory parameter which is undefined
            if parameter.mandatory {
                errors.append(ValidatorError.undefinedMandatoryParameter(name: event.name, key: key))
            }
        }

        if event.name == SetUserIdEvent.Constants.name,
            let userID = event.context[SetUserIdEvent.Constants.Key.userId] as? String {
            let userID = userID.trimmingCharacters(in: .whitespaces)
            if userID.count > Constants.legalUserIdLength {
                errors.append(ValidatorError.tooLongUserId(userId: userID, limit: Constants.legalUserIdLength))
            }
            let validationResult = UserIDValidator(storage: storage).validateNewUserID(userID)
            switch validationResult {
            case .valid:
                NewUserIDHandler(storage: storage).handle(userID: userID)
            default:
                errors.append(ValidatorError.invalidUserId(userId: userID))
            }
        }

        if event.name == SetUserEmailEvent.Constants.name, let email = event.context[SetUserEmailEvent.Constants.Key.email] as? String {
            let validationResult = EmailValidator(storage: storage).isValid(email)
            switch validationResult {
            case .valid:
                NewEmailHandler(storage: storage).handle(email: email)
            default:
                errors.append(ValidatorError.invalidEmail(email: email))
            }
        }

        /// Verify event' parameters
        for (key, value) in event.context {
            /// Check undefined parameter
            guard let parameter = eventConfiguration.parameters[key] else {
                errors.append(ValidatorError.undefinedParameter(key: key))
                continue
            }
            do {
                try validateParameter(parameter, key, value)
            } catch {
                if let error = error as? ValidatorError {
                    errors.append(error)
                }
                throw error
            }
        }

        event.validations = errors.map(translateToValidationIssue)
    }

    func translateToValidationIssue(error: ValidatorError) -> ValidationIssue {
        return ValidationIssue(
            status: error.status,
            message: error.localizedDescription
        )
    }

    private func validateParameter(
        _ parameter: Parameter,
        _ key: String,
        _ value: Any
    ) throws {
        guard let parameterType = Constants.AllowedType(rawValue: parameter.type) else {
            throw ValidatorError.unsupportedType(key: key)
        }
        switch parameterType {
        case .number:
            guard let numberValue = value as? NSNumber else {
                throw ValidatorError.wrongType(key: key, expected: .number)
            }
            if String(describing: numberValue).count > Constants.legalParameterLength {
                throw ValidatorError.limitOfCharacters(key: key, limit: Constants.legalParameterLength)
            }

        case .string:
            guard let stringValue = value as? String else {
                throw ValidatorError.wrongType(key: key, expected: .string)
            }
            if stringValue.count > Constants.legalParameterLength {
                throw ValidatorError.limitOfCharacters(key: key, limit: Constants.legalParameterLength)
            }

        case .boolean:
            guard value is Bool else {
                throw ValidatorError.wrongType(key: key, expected: .boolean)
            }
        }
    }
}

enum ValidatorError: LocalizedError, Equatable {
    case undefinedName(name: String)
    case limitOfParameters(name: String, actual: Int, limit: Int)
    case undefinedMandatoryParameter(name: String, key: String)
    case undefinedParameter(key: String)
    case limitOfCharacters(key: String, limit: Int)
    case unsupportedType(key: String)
    case wrongType(key: String, expected: EventValidator.Constants.AllowedType)
    case invalidUserId(userId: String)
    case tooLongUserId(userId: String, limit: Int)
    case invalidEmail(email: String)

    var errorDescription: String? {
        switch self {
        case let .undefinedName(name):
            return """
            '\(name)' is an undefined event
            """
        case let .limitOfParameters(name, actual, limit):
            return """
            event \(name) contains \(actual) parameters while the allowed number of parameters is \(limit). Some parameters were removed to process the event.
            """
        case let .undefinedParameter(key):
            return """
            \(key) is an undefined parameter. It will not be tracked and cannot be used within a trigger.
            """
        case let .undefinedMandatoryParameter(name, key):
            return """
            event \(name) has a mandatory parameter, \(key), which is undefined or empty.
            """
        case let .limitOfCharacters(key, limit):
            return """
            '\(key)' has exceeded the limit of allowed number of characters. The character limit is \(limit)
            """
        case let .unsupportedType(key):
            return """
            '\(key)' should be of only TYPE of boolean or string or number
            """
        case let .wrongType(key, expected):
            return """
            '\(key)' should be of TYPE \(expected.rawValue)
            """
        case let .invalidUserId(userId):
            return """
            userId, \(userId), is invalid
            """
        case let .tooLongUserId(userId, limit):
            return """
            "userId, '\(userId)', is too long, the userId limit is \(limit)."
            """
        case let .invalidEmail(email):
            return """
            email, '\(email)', is invalid.
            """
        }
    }

    var status: ValidationIssue.Status {
         switch self {
         case .undefinedName,
              .undefinedMandatoryParameter,
              .limitOfCharacters,
              .unsupportedType,
              .wrongType,
              .invalidUserId,
              .tooLongUserId,
              .invalidEmail:
             return .error
         case .limitOfParameters,
              .undefinedParameter:
             return .warning
         }
     }

}
