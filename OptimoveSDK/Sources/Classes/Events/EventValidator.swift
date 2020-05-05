//  Copyright © 2017 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class EventValidator: Node {

    enum Error: LocalizedError, Equatable {
        case invalidEvent
        case illegalParameterLength
        case mismatchParamterType
        case mandatoryParameterMissing(String)

        var errorDescription: String? {
            switch self {
            case .invalidEvent:
                return "invalidEvent"
            case .illegalParameterLength:
                return "illegalParameterLength"
            case .mismatchParamterType:
                return "mismatchParamterType"
            case .mandatoryParameterMissing(let parameterName):
                return "mandatoryParameterMissing \(parameterName)"
            }
        }
    }

    private struct Constants {
        static let string = "String"
        static let number = "Number"
        static let boolean = "Boolean"
    }

    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    override func execute(_ operation: Operation) throws {
        let validationFunction = { [configuration] () -> Operation in
            switch operation {
            case let .report(event: event):
                let eventConfig = try event.matchConfiguration(with: configuration.events)
                try self.validate(event: event, withConfig: eventConfig)
                return operation
            default:
                return operation
            }
        }
        try next?.execute(validationFunction())
    }

    private func validate(event: Event, withConfig eventConfiguration: EventsConfig) throws {
        // Verify mandatory parameter exist
        for (name, parameter) in eventConfiguration.parameters where parameter.mandatory {
            if event.context[name] == nil {
                throw Error.mandatoryParameterMissing(name)
            }
        }
        // Verify Type is as defined
        for (key, value) in event.context {
            if let parameterConfiguration = eventConfiguration.parameters[key] {
                switch parameterConfiguration.type {
                case Constants.number:
                    guard let numberValue = value as? NSNumber else {
                        Logger.error("Parameter '\(key)' is not number type.")
                        throw Error.mismatchParamterType
                    }
                    // Verify parameter value
                    if String(describing: numberValue).count > 255 {
                        throw Error.illegalParameterLength
                    }
                case Constants.string:
                    guard let stringValue = value as? String else {
                        Logger.error("Parameter \(key) is not string type.")
                        throw Error.mismatchParamterType
                    }
                    // Verify parameter value length
                    if stringValue.count > 255 {
                        throw Error.illegalParameterLength
                    }
                case Constants.boolean:
                    guard value is Bool else {
                        Logger.error("Parameter \(key) is not boolean type.")
                        throw Error.mismatchParamterType
                    }
                default:
                    throw Error.invalidEvent
                }
            }
        }
    }

}
