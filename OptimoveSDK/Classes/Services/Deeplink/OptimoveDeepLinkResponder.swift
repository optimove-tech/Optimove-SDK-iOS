//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

@objc public protocol OptimoveDeepLinkCallback {
    @objc func didReceive(deepLink: OptimoveDeepLinkComponents?)
}

@objc public class OptimoveDeepLinkResponder: NSObject {
    private let deepLinkCallback: OptimoveDeepLinkCallback

    @objc public init(_ deepLinkCallback: OptimoveDeepLinkCallback) {
        self.deepLinkCallback = deepLinkCallback
    }

    @objc func didReceive(deepLinkComponent: OptimoveDeepLinkComponents) {
        deepLinkCallback.didReceive(deepLink: deepLinkComponent)
    }
}

@objc public class OptimoveDeepLinkComponents: NSObject {
    @objc public var screenName: String
    @objc public var parameters: [String: String]?

    @objc init(screenName: String, parameters: [String: String]?) {
        self.screenName = screenName
        self.parameters = parameters
    }

}
