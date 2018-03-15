//
//  OptimoveFileManager.swift
//  OptimoveSDK
//
//  Created by Elkana Orbach on 17/12/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

import os

public class OptimoveFileManager {
    public let appSupportDirectory : URL
    public var optimoveSDKDirectory: URL
    private init()
    {
        appSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory,
                                                       in: .userDomainMask)[0]
        optimoveSDKDirectory = appSupportDirectory.appendingPathComponent("OptimoveSDK")
    }
    public static let shared = OptimoveFileManager()
    func writeRegistrationFile(fileName:String, withData data:Data)
    {
        do
        {
            try FileManager.default.createDirectory(at: OptimoveFileManager.shared.optimoveSDKDirectory, withIntermediateDirectories: true)
            let fileURL = OptimoveFileManager.shared.optimoveSDKDirectory.appendingPathComponent(fileName)
            let success = FileManager.default.createFile(atPath: fileURL.path, contents: data, attributes: nil)
            Optimove.sharedInstance.logger.debug("Storing status is \(success.description)\n location:\(OptimoveFileManager.shared.optimoveSDKDirectory.path)")
        }
        catch
        {
//            Optimove.sharedInstance.logger.severe("\(OptimoveError.cantStoreFileInLocalStorage.localizedDescription)")
            return
        }
    }
}
