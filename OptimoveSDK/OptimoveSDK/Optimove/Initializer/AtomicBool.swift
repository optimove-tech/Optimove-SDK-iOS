//
//  AtomicBool.swift
//  OptimoveSDK
//
//  Created by Elkana Orbach on 09/01/2018.
//  Copyright © 2018 Optimove. All rights reserved.
//

import Foundation

class AtomicBool {
    private static let lock = NSLock()
    private var val: Bool

    init() {
        val = false
    }
    
    func compareAndSet(expected:Bool,value:Bool) -> Bool
    {
        if expected != val { return false}
        AtomicBool.lock.lock()
        Optimove.sharedInstance.logger.debug("expected value:\(expected)")
        Optimove.sharedInstance.logger.debug("current value:\(val)")
        if expected != val {
            AtomicBool.lock.unlock()
            return false
        }
        val = value
        AtomicBool.lock.unlock()
        return true
    }
    
}
