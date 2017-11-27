//
//  Synchronizable.swift
//  OptimoveSDKDev
//
//  Created by Mobile Developer Optimove on 11/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

protocol Synchronizable
{
    func setDefaultObjectAndSynchronize(forObject object : Any, key : String)
}

extension Synchronizable
{
    func setDefaultObjectAndSynchronize(forObject object : Any, key : String)
    {
        UserDefaults.standard.set(object, forKey: key)
        UserDefaults.standard.synchronize()
    }
}
