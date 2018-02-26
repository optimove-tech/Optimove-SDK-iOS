//
//  ConfigurationProvider.swift
//  iOS-SDK
//
//  Created by Mobile Developer Optimove on 04/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

struct ConfigurationProvider
{
    static func getConfigurationDetails(token:String,version:String,resultBlock: @escaping ResultBlockWithValue)
    {
        let path = "\(UserInSession.shared.configurationEndPoint)/\(token)/\(version).json"
        
        Optimove.sharedInstance.logger.debug("Connect to \(path) to retreive configuration file ")
        
        if let url = URL(string: path)
        {
            let task = URLSession.shared.dataTask(with: url)
            { (data, response, error) in
                DispatchQueue.main.async {
                    guard error == nil
                        else
                    {
                        Optimove.sharedInstance.logger.severe("\(error.debugDescription)")
                        return resultBlock(nil, error as? OptimoveError)
                    }
                    guard (response as? HTTPURLResponse)?.statusCode == 200 else
                    {
                        
                        Optimove.sharedInstance.logger.severe("Issue with configuration response")
                        return resultBlock(nil, OptimoveError.error )
                    }
                    
                    Optimove.sharedInstance.logger.debug("Configuration file arrived 😃 ")
                    resultBlock(data,nil)
                }
            }
            task.resume()
        }
        
    }
}
