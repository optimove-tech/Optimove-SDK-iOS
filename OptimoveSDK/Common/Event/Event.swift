//
//  Event.swift
//  OptimoveSDKDev
//
//  Created by Mobile Developer Optimove on 06/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

@objc public protocol OptimoveEvent
{
     var name : String
    {
        get
    }
     var parameters: [String:Any]
    {
        get
    }
}
