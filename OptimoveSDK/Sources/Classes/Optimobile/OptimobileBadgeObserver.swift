//  Copyright © 2022 Optimove. All rights reserved.

import Foundation
import UIKit

class OptimobileBadgeObserver: NSObject {

    typealias BadgeChangedCallback = (Int) -> Void

    var _callback: BadgeChangedCallback!

    init(callback: @escaping BadgeChangedCallback) {
        super.init()
        _callback = callback

        UIApplication.shared.addObserver(self, forKeyPath: "applicationIconBadgeNumber", options: .new, context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {

        if (keyPath?.elementsEqual("applicationIconBadgeNumber")) != nil {
            let newBadgeCount = change![NSKeyValueChangeKey(rawValue: "new")]
            _callback(newBadgeCount as! Int)
        }
    }
}
