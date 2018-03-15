//
//  OptimoveRegistrationApiPaths.swift
//  iOS-SDK
//
//  Created by Mobile Developer Optimove on 04/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

enum OptimoveRegistrationPath: String
{
    
    case optInOutVisitorPath    = "optInOutVisitor"
    case optInOutCustomerPath   = "optInOutCustomer"
    case registerCustomerPath   = "registerCustomer"
    case unregisterCustomerPath = "unregisterCustomer"
    case registerVisitorPath    = "registerVisitor"
    case unregisterVisitorPath  = "unregisterVisitor"
}

class OptimoveRegistrationApiPaths
{
    static func pathForOptInOutCustomer() -> String
    {
        return  OptimoveRegistrationPath.optInOutCustomerPath.rawValue
    }
    
    static func pathForOptInOutVisitor() -> String
    {
        return  OptimoveRegistrationPath.optInOutVisitorPath.rawValue
    }
    
    static func pathForRegisterCustomer() -> String
    {
        return  OptimoveRegistrationPath.registerCustomerPath.rawValue
    }
    
    static func pathForUnregisterCustomer() -> String
    {
        return OptimoveRegistrationPath.unregisterCustomerPath.rawValue
    }
    
    static func pathForRegisterVisitor() -> String
    {
        return OptimoveRegistrationPath.registerVisitorPath.rawValue
    }
    
    static func pathForUnregisterVisitor() -> String
    {
        return OptimoveRegistrationPath.unregisterVisitorPath.rawValue
    }
}
