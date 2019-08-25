//  Copyright © 2017 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class OptimoveEventValidator {

    private struct Constants {
        static let string = "String"
        static let number = "Number"
        static let boolean = "Boolean"
    }

    /// Must pass the decorator in case some additional attributes become mandatory
    ///
    /// - Parameters:
    ///   - event: Event for validation.
    ///   - config: Required additional attributes.
    /// - Throws: Throwed en error if validation failed.
    static func validate(event: OptimoveEvent, withConfig config: EventsConfig) throws {
        // Verify mandatory parameter exist
        for (name, paramConfigs) in config.parameters where paramConfigs.mandatory {
            if event.parameters[name] == nil {
                throw OptimoveError.mandatoryParameterMissing
            }
        }
        // Verify Type is as defined
        for (name, value) in event.parameters {
            if let parameterConfiguration = config.parameters[name] {
                switch parameterConfiguration.type {
                case Constants.number:
                    guard let numberValue = value as? NSNumber else {
                        Logger.error("Parameter '\(name)' is not number type.")
                        throw OptimoveError .mismatchParamterType
                    }
                    // Verify parameter value
                    if String(describing: numberValue).count > 255 {
                        throw OptimoveError .illegalParameterLength
                    }

                case Constants.string:
                    guard let stringValue = value as? String else {
                        Logger.error("Parameter \(name) is not string type.")
                        throw OptimoveError.mismatchParamterType
                    }
                    // Verify parameter value length
                    if stringValue.count > 255 {
                        throw OptimoveError.illegalParameterLength

                    }
                case Constants.boolean:
                    guard value is Bool else {
                        Logger.error("Parameter \(name) is not boolean type.")
                        throw OptimoveError.mismatchParamterType
                    }
                default:
                    throw OptimoveError.invalidEvent
                }
            }
        }
    }

}
