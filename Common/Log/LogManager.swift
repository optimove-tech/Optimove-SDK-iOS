//
//  LogManager.swift
//  OptimoveSDKDev
//
//  Created by Mobile Developer Optimove on 18/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

class LogManager
{
    //  Random reports
    static func reportToConsole(_ msgToConsole : String)
    {
        if ShouldLogToConsole
        {
            print("✏️ " + msgToConsole)
        }
    }
    
    static func reportData(_ data: Data)
    {
        if ShouldLogToConsole
        {
            print("📝 " + (String(data:data,encoding:.utf8) ?? "no data"))
        }
    }
    
    //  Algorithm success
    static func reportSuccessToConsole(_ msgToConsole : String)
    {
        if ShouldLogToConsole
        {
            print("👍🏻 " + msgToConsole)
        }
    }
    
    //  Algorithm failure
    static func reportFailureToConsole(_ msgToConsole : String)
    {
        let message = "👎🏻 " + msgToConsole
        
        if ShouldLogToConsole
        {
            print(message)
        }
    }
    
    //  JSON fetched and parsed
    static func reportJSONCompleted(fromMethod msgToConsole : String)
    {
        if ShouldLogToConsole
        {
            print("🏄 feteched JSON from method: " + msgToConsole)
        }
    }
    
    //  API Server error
    static func reportServerError(_ error : Error)
    {
        if ShouldLogToConsole
        {
            print("❎ Server Error: " + error.localizedDescription)
        }
    }
    
    static func reportError(error : Error?)
    {
        if error == nil
        {
            return
        }
        if error!.localizedDescription.isEmpty == true
        {
            return
        }
        if ShouldLogToConsole
        {
            print("❌ Error: " + error!.localizedDescription)
        }
    }
}
