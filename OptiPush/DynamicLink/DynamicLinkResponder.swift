//
//  DynamicLinkResponder.swift
//  DevelopSDK
//
//  Created by Elkana Orbach on 22/11/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

public protocol DynamicLinkCallback
{
    func didReceive(dynamicLink: DynamicLinkComponents)
}

public class DynamicLinkResponder: NSObject
{
    private let dynamicLinkCallback: DynamicLinkCallback
    
    public init(_ dynamicLinkCallback: DynamicLinkCallback)
    {
        self.dynamicLinkCallback = dynamicLinkCallback
        super.init()
    }
    
    func didReceive(dynamicLink: DynamicLinkComponents)
    {
        dynamicLinkCallback.didReceive(dynamicLink: dynamicLink)
    }
}

public struct DynamicLinkComponents
{
    public var screenName : String
    public var query: [String:String]
}
