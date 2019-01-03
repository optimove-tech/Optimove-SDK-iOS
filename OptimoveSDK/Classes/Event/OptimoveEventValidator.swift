//
//  EventValidator.swift
//  OptimoveSDKDev
//
//  Created by Mobile Developer Optimove on 05/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

class OptimoveEventValidator
{
    //MARK: - Internal Methods
    func validate(event: OptimoveEvent, withConfig config: OptimoveEventConfig) -> OptimoveError?
    {
        //Verify mandatory parameter exist
        for (name, paramConfigs) in config.parameters
        {
            if paramConfigs.mandatory
            {
                if  event.parameters[name] == nil
                {
                    return .mandatoryParameterMissing
                }
            }
        }
        //Verify Type is as defined
        for (name, value) in event.parameters
        {
            if let parameterConfiguration = config.parameters[name]
            {
                switch parameterConfiguration.type
                {
                case "Number":
                    guard let numberValue = value as? NSNumber else
                    {
                        OptiLogger.error("parameter \(name) is not number type")
                        return .mismatchParamterType
                    }
                    if String(describing: numberValue).count > 255 // Verify parameter value
                    {
                        return .illegalParameterLength
                    }
                    
                case "String":
                    guard let stringValue = value as? String
                        else
                    {
                         OptiLogger.error("parameter \(name) is not string type")
                        return .mismatchParamterType
                        
                    }
                    // Verify parameter value length
                    if stringValue.count > 255
                    {
                        return .illegalParameterLength
                        
                    }
                case "Boolean":
                    guard let _ = value as? Bool
                        else
                    {
                        OptiLogger.error("parameter \(name) is not boolean type")
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
