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
public typealias ResultBlockWithArrayAndString = (Array<Any>?, String, OptimoveError?) -> Void
public typealias ResultBlockWithValue = (Any? , OptimoveError?) ->  Void


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
    static func generateRequest(toUrl url:URL,json:Data) -> URLRequest
    {
        var request = URLRequest(url: url)
        request.timeoutInterval = 60
        request.httpMethod = HttpMethod.post.rawValue
        request.httpBody = json
        request.setValue(MediaType.json.rawValue,
                         forHTTPHeaderField: HttpHeader.contentType.rawValue)
        return request
    }
    
    fileprivate static func composeTopicRegistrationRequest(_ fcmToken: String, _ topics: [String]) -> Data {
        var requestJsonData = [String: Any]()
        requestJsonData[Keys.Topics.fcmToken.rawValue] = fcmToken
        requestJsonData[Keys.Topics.topics.rawValue] = topics
        return try! JSONSerialization.data(withJSONObject: requestJsonData, options: .prettyPrinted)
    }
    
    static func register(fcmToken:String, toTopics topics: [String])
    {
        func generateRegistrationSessionDataTask(fromRequest request:URLRequest) -> URLSessionDataTask
        {
            let task = URLSession.shared.dataTask(with: request)
            { (data, response, error) in
                
            }
            return task
        }
        
        var endPoint = ""
        if let ep = Optimove.sharedInstance.optiPush?.registrar.reportEndPoint {
         endPoint = ep + "registerClientToTopics"
        }
        
        if let url  = URL(string: endPoint)
        {
            let json = composeTopicRegistrationRequest(fcmToken, topics)
            let request = NetworkManager.generateRequest(toUrl: url,json: json )
            let task = generateRegistrationSessionDataTask(fromRequest: request)
            task.resume()
        }
    }
    
    static func unregister(fcmToken:String, fromTopics topics: [String])
    {
        func generateRegistrationSessionDataTask(fromRequest request:URLRequest) -> URLSessionDataTask
        {
            let task = URLSession.shared.dataTask(with: request)
            { (data, response, error) in
                
            }
            return task
        }
        
        var endPoint = ""
        if let ep = Optimove.sharedInstance.optiPush?.registrar.reportEndPoint {
            endPoint = ep + "unregisterClientFromTopics"
        }
        
        if let url  = URL(string: endPoint)
        {
            let json = composeTopicRegistrationRequest(fcmToken, topics)
            let request = NetworkManager.generateRequest(toUrl: url,json: json )
            let task = generateRegistrationSessionDataTask(fromRequest: request)
            task.resume()
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
