//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

/// The protocol for a subscription and receiving deep links from Optimove SDK.
@objc public protocol OptimoveDeepLinkCallback {
    /// Method will be called on a new incoming deeplink.
    /// - Parameter deepLink: A deeplink components.
    @objc func didReceive(deepLink: OptimoveDeepLinkComponents?)
}

/// A responder wrapper for Objective-C.
/// - NOTE: Remove in a future version.
@objc public class OptimoveDeepLinkResponder: NSObject {
    private weak var receiver: OptimoveDeepLinkCallback?

    @objc public init(_ receiver: OptimoveDeepLinkCallback) {
        self.receiver = receiver
    }

    @objc func didReceive(deepLinkComponent: OptimoveDeepLinkComponents) {
        receiver?.didReceive(deepLink: deepLinkComponent)
    }
}

/// The representation class of an incoming deeplink.
@objc public class OptimoveDeepLinkComponents: NSObject {
    /// A screen name to open.
    @objc public var screenName: String
    /// Additional parameters.
    @objc public var parameters: [String: String]?

    @objc init(screenName: String, parameters: [String: String]?) {
        self.screenName = screenName
        self.parameters = parameters
    }

}
