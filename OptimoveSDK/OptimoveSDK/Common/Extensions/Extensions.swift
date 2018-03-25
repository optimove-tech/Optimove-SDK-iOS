//
//  Extensions.swift
//  iOS-SDK
//
//  Created by Mobile Developer Optimove on 04/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

extension String
{
    func contains(_ find: String) -> Bool
    {
        return self.range(of: find) != nil
    }
    
    func containsIgnoringCase(_ find: String) -> Bool
    {
        return self.range(of: find, options: .caseInsensitive) != nil
    }
    
    func setAsMongoKey() -> String
    {
        return self.replacingOccurrences(of: ".", with: "_")
    }
}

extension URL
{
    public var queryParameters: [String: String]?
    {
        guard let components = URLComponents(url: self,
                                             resolvingAgainstBaseURL: true),
            let queryItems = components.queryItems else
        {
            return nil
        }
        
        var parameters = [String: String]()
        for item in queryItems
        {
            parameters[item.name] = item.value
        }
        return parameters
    }
}

extension Data
{
    static func extractJSONFrom(data:Data?) -> (json:[String:Any]?,error:OptimoveError?)
    {
        if let data = data
        {
            let json:[String:Any]!
            do
            {
                json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
            }
            catch
            {
                return (nil, .canNotParseData)
            }
            return (json, nil)
        }
        return (nil,.emptyData)
    }
}
