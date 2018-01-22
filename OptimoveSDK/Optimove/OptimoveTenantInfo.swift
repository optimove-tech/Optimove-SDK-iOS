//
//  OptimoveTenantInfo.swift
//  OptimoveSDK
//
//  Created by Mobile Developer Optimove on 28/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

@objc public class OptimoveTenantInfo: NSObject
{
    @objc public var url          :String
    @objc public var token        : String
    @objc public var version      : String
    @objc public var hasFirebase  : Bool
    
    @objc public init(url:String,
                token: String,
                version     : String,
                hasFirebase : Bool
        )
    {
        self.hasFirebase = hasFirebase
        self.url = url
        self.token = token
        self.version = version
    }
}
