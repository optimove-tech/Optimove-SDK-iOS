//
//  KSBadgeObserver.swift
//  OptimoveSDK
//
//  Created by Barak Ben Hur on 07/04/2022.
//

import Foundation
import UIKit

class KSBadgeObserver: NSObject {
    
    typealias KSBadgeChangedCallback = (Int) -> ()
    
    var _callback: KSBadgeChangedCallback!
    
    init(callback: @escaping KSBadgeChangedCallback) {
        super.init()
        _callback = callback
        
        UIApplication.shared.addObserver(self, forKeyPath: "applicationIconBadgeNumber",options: .new, context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
       
        if ((keyPath?.elementsEqual("applicationIconBadgeNumber")) != nil) {
            let newBadgeCount = change![NSKeyValueChangeKey(rawValue: "new")]
            _callback(newBadgeCount as! Int)
        }
    }
}
