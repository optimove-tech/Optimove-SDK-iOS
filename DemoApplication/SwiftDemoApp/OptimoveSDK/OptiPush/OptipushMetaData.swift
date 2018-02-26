//
//  OptipushMetaData.swift
//  OptimoveSDK
//
//  Created by Mobile Developer Optimove on 05/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation


struct OptipushMetaData
{
    var registrationServiceRegistrationEndPoint : String
    var registrationServiceOtherEndPoint        : String
}

extension OptipushMetaData
{
    static func parseOptipushMetaData(from json:[String:Any]) -> OptipushMetaData?
    {
        guard let optipushRegistrationEndpoint                          = json[Keys.Configuration.registrationServiceRegistrationEndPoint.rawValue] as? String,
            let   optipushGeneralEndPoint                               = json[Keys.Configuration.registrationServiceOtherEndPoint.rawValue] as? String
            else {return nil}
        
        return OptipushMetaData(registrationServiceRegistrationEndPoint: optipushRegistrationEndpoint,
                                registrationServiceOtherEndPoint: optipushGeneralEndPoint)
        
    }
}
