//
//  EventValidator.swift
//  OptimoveSDKDev
//
//  Created by Mobile Developer Optimove on 05/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation
import os.log

class EventValidator
{
    //MARK: - Internal Varaibles
    var eventsConfigs: [String:EventConfig]
    
    //MARK: - Constructors
    init?(from json:[String:Any])
    {
        Optimove.sharedInstance.logger.debug("Initialize Validator")
        
        self.eventsConfigs = [:]
        guard let events = json[Keys.Configuration.events.rawValue] as? [String:Any] else {return nil}
        for (name, configJSON) in events
        {
            guard let configs = configJSON as? [String:Any],
                let event = EventConfig(from: configs)
                else {return nil }
            self.eventsConfigs[name] = event
        }
        Optimove.sharedInstance.logger.debug("Finish initializing Validator")
    }
    
    //MARK: - Internal Methods
    func validate(event: OptimoveEvent, completionHandler: ResultBlockWithError)
    {
        guard let configurations = eventsConfigs[event.name]
            else
        {
            completionHandler(.invalidEvent) // Verify event exist in configuration
            return
        }
        
        for (_, paramConfigs) in configurations.params
        {
            if paramConfigs.mandatory
            {
                if  event.parameters[paramConfigs.name] == nil
                {
                    completionHandler(.mandatoryParameterMissing)   //Verify mandatory parameter exist
                    return
                }
            }
        }
        for (name, value) in event.parameters
        {
            guard let config = configurations.params[name]
            else
            {
                completionHandler(.invalidEvent) //Verify client parameter exist in configurations
                return
            }
            switch config.type //Verify Type is as defined
            {
                case "number":
                    guard let numberValue = value as? NSNumber
                    else
                    {
                        completionHandler(.invalidEvent)
                        return
                    }
                    if String(describing: numberValue).count > 255 // Verify parameter value
                    {
                        completionHandler(.invalidEvent)
                        return
                    }

                case "string":
                    guard let stringValue = value as? String
                    else
                    {
                        completionHandler(.invalidEvent)
                        return
                    }
                    if stringValue.count > 255 // Verify parameter value
                    {
                        completionHandler(.invalidEvent)
                        return
                    }
                default:
                    completionHandler(.invalidEvent)
            }
        }
        completionHandler(nil)
    }
}
