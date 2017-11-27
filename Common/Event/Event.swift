//
//  Event.swift
//  OptimoveSDKDev
//
//  Created by Mobile Developer Optimove on 06/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

public protocol OptimoveEvent
{
     var name : String
    {
        get
    }
     var paramaeters: [String:Any]
    {
        get
    }
}
