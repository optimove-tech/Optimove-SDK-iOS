//
//  OptimoveTenantInfo.swift
//  OptimoveSDK
//
//  Created by Mobile Developer Optimove on 28/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

public struct OptimoveTenantInfo
{
    public var token       : String
    public var version     : String
    public var hasFirebase : Bool
    
    public init(token: String,
                version     : String,
                hasFirebase : Bool)
    {
        self.hasFirebase = hasFirebase
        self.token = token
        self.version = version
    }
}
