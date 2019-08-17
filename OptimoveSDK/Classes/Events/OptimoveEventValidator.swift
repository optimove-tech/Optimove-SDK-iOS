//  Copyright © 2017 Optimove. All rights reserved.

import Foundation
import OptimoveCore

class OptimoveEventValidator {
    // MARK: - Internal Methods
    func validate(event: OptimoveEvent, withConfig config: EventsConfig) -> OptimoveError? {
        //Verify mandatory parameter exist
        for (name, paramConfigs) in config.parameters where paramConfigs.mandatory {
            if event.parameters[name] == nil {
                return .mandatoryParameterMissing
            }
        }
        //Verify Type is as defined
        for (name, value) in event.parameters {
            if let parameterConfiguration = config.parameters[name] {
                switch parameterConfiguration.type {
                case "Number":
                    guard let numberValue = value as? NSNumber else {
                        OptiLoggerMessages.logParameterIsNotNumber(name: name)
                        return .mismatchParamterType
                    }
                    if String(describing: numberValue).count > 255  // Verify parameter value
                    {
                        return .illegalParameterLength
                    }

                case "String":
                    guard let stringValue = value as? String
                    else {
                        OptiLoggerMessages.logParameterIsNotString(name: name)
                        return .mismatchParamterType

                    }
                    // Verify parameter value length
                    if stringValue.count > 255 {
                        return .illegalParameterLength

                    }
                case "Boolean":
                    guard let _ = value as? Bool
                    else {
                        OptiLoggerMessages.logParameterIsNotBoolean(name: name)
                        return .mismatchParamterType
                    }

                default:
                    return .invalidEvent
                }
            }
        }
        return nil
    }

}
