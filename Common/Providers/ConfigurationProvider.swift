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
        let path = "\(URLPaths.base)/\(token)/\(version).json"
        LogManager.reportToConsole("Connect to \(path) to retreive configuration file ")
        if let url = URL(string: path)
        {
            let request = URLRequest(url: url)
            
            let task = URLSession.shared.dataTask(with: request)
            { (data, response, error) in
                
                guard error == nil
                    else
                {
                    LogManager.reportError(error: error)
                    return resultBlock(nil, error)
                }
                LogManager.reportSuccessToConsole("Configuration file arrived 😃")
                LogManager.reportToConsole("Parsing Optipush Meta Data")
                guard let parsedConfigurations = Parser.getLegitJSON(data: data,
                                                                     response: response,
                                                                     error: error).json else
                {
                    resultBlock(nil, error)
                    return
                }
                LogManager.reportToConsole("Configuration Parsing succeeded")
                resultBlock(parsedConfigurations, error)
                
            }
            task.resume()
        }
    }
}
