//
//  NetworkAPIPaths.swift
//  iOS-SDK
//
//  Created by Mobile Developer Optimove on 04/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

enum RegisterPath: String
{
    
    case optInOutVisitorPath    = "optInOutVisitor"
    case optInOutCustomerPath   = "optInOutCustomer"
    case registerCustomerPath   = "registerCustomer"
    case unregisterCustomerPath = "unregisterCustomer"
    case registerVisitorPath    = "registerVisitor"
    case unregisterVisitorPath  = "unregisterVisitor"
}

class NetworkAPIPaths
{
    static func pathForOptInOutCustomer() -> String
    {
        return  RegisterPath.optInOutCustomerPath.rawValue
    }
    
    static func pathForOptInOutVisitor() -> String
    {
        return  RegisterPath.optInOutVisitorPath.rawValue
    }
    
    static func pathForRegisterCustomer() -> String
    {
        return  RegisterPath.registerCustomerPath.rawValue
    }
    
    static func pathForUnregisterCustomer() -> String
    {
        return RegisterPath.unregisterCustomerPath.rawValue
    }
    
    static func pathForRegisterVisitor() -> String
    {
        return RegisterPath.registerVisitorPath.rawValue
    }
    
    static func pathForUnregisterVisitor() -> String
    {
        return RegisterPath.unregisterVisitorPath.rawValue
    }
}
