//
//  OptimoveEvent.swift
//  iOS-SDK
//
//  Created by Mobile Developer Optimove on 04/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

struct EventConfig
{
    struct Parameter
    {
        var mandatory:Bool
        var name: String
        var id: Int
        var type : String
        var optitrackDimensionID: Int
        
        init?(dictionary: [String:Any])
        {
            guard let name = dictionary[Keys.Configuration.name.rawValue] as? String,
                let id = dictionary[Keys.Configuration.id.rawValue] as? Int,
                let optional = dictionary[Keys.Configuration.optional.rawValue] as? Bool,
                let type = dictionary[Keys.Configuration.type.rawValue] as? String,
                let dimensionID = dictionary[Keys.Configuration.optiTrackDimensionId.rawValue] as? Int
                else {return nil}
            self.name = name
            self.id = id
            self.mandatory = !optional
            self.type = type
            self.optitrackDimensionID = dimensionID
        }
    }
    
    var id: Int
    var supportedComponents: [Component:Bool]
    var params: [String:Parameter]
    
    init?(from json: [String:Any])
    {
        guard let id = json[Keys.Configuration.id.rawValue] as? Int,
            let supportedOnOptitrack = json[Keys.Configuration.supportedOnOptitrack.rawValue] as? Bool,
            let supportedOnRealTime = json[Keys.Configuration.supportedOnRealTime.rawValue] as? Bool,
            let parametersJSON = json[Keys.Configuration.parameters.rawValue] as? [String: Any]
            else {return nil}
        self.id = id
        self.supportedComponents = [:]
        self.supportedComponents[.optiTrack] = supportedOnOptitrack
        self.params = [:]
        
        for (name, paramConfigs) in parametersJSON
        {
            guard let configs = paramConfigs as? [String:Any],
            let parameter = Parameter(dictionary: configs)
            else {return nil}
            self.params[name] = parameter
        }
        
    }
}
