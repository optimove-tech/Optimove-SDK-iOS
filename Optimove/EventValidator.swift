//
//  EventValidator.swift
//  OptimoveSDKDev
//
//  Created by Mobile Developer Optimove on 05/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

class EventValidator
{
    //MARK: - Internal Varaibles
    var eventsConfigs: [String:EventConfig]
    
    //MARK: - Constructors
    init(eventConfigs: [String:EventConfig] = [:])
    {
        LogManager.reportToConsole("Initialize Validator")
        self.eventsConfigs = eventConfigs
        LogManager.reportToConsole("Finish initializing Validator")
    }
    
    //MARK: - Internal Methods
    func loadConfigs(from json:[String:Any]) -> Bool
    {
        guard let events = json[Keys.Configuration.events.rawValue] as? [String:Any] else {return false}
        for (name, configJSON) in events
        {
            guard let configs = configJSON as? [String:Any],
                let event = EventConfig(from: configs)
                else {return false }
            eventsConfigs[name] = event
        }
        return true
    }
    
    func validate(event: OptimoveEvent, completionHandler: ResultBlockWithError)
    {
        guard let configurations = eventsConfigs[event.name]
            else
        {
            completionHandler(.invalidEvent) // Verify event exist in configuration
            return
        }
        
        for (paramName, paramConfigs) in configurations.params
        {
            if paramConfigs.mandatory
            {
                if  event.paramaeters[paramConfigs.name] == nil
                {
                    completionHandler(.mandatoryParameterMissing)   //Verify mandatory parameter exist
                    return
                }
            }
        }
        for (name, value) in event.paramaeters
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
                    guard let numberValue = value as? NSNumber //TODO: Test in playground
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
