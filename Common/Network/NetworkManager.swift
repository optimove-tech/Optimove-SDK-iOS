//
//  NetworkManager.swift
//  iOS-SDK
//
//  Created by Mobile Developer Optimove on 04/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation
import SystemConfiguration

let backgroundQueue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)

//  MARK: Closure typealias
public typealias ResultBlock = () -> Void
public typealias ResultBlockWithError = (OptimoveError?) -> Void
public typealias ResultBlockWithErrors = ([OptimoveError]) -> Void
public typealias ResultBlockWithBool = (Bool) -> Void
public typealias ResultBlockWithModelArray = (Array<Any>?, Error?) -> Void
public typealias ResultBlockWithArrayAndString = (Array<Any>?, String, Error?) -> Void
public typealias ResultBlockWithValue = (Any? , Error?) ->  Void


class NetworkManager
{
    static func getInitConfigurations(token:String,
                                      version:String,
                                      didComplete:@escaping ResultBlockWithValue)
    {
        ConfigurationProvider.getConfigurationDetails(token: token,
                                                      version: version)
        { (data, error) in
            didComplete(data, error)
        }
    }
    
}

func isInternetAvailable() -> Bool
{
    var zeroAddress = sockaddr_in()
    zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
    zeroAddress.sin_family = sa_family_t(AF_INET)
    
    let defaultRouteReachability = withUnsafePointer(to: &zeroAddress)
    {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1)
        { zeroSockAddress in
            SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
        }
    }
    
    var flags = SCNetworkReachabilityFlags()
    if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
        return false
    }
    let isReachable = flags.contains(.reachable)
    let needsConnection = flags.contains(.connectionRequired)
    return (isReachable && !needsConnection)
}
