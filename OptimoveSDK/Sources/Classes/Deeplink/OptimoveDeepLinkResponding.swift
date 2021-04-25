//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

/// The protocol proposes a subscription logic for deep-links from the Optimove platform.
@objc protocol OptimoveDeepLinkResponding {

    /// The Deeplink subscription to receive a deep link from Optimove notification payload.
    /// - Parameter responder: A deeplink responder.
    @objc func register(deepLinkResponder responder: OptimoveDeepLinkResponder)

    /// Unsubscribe from the Deeplink subscription.
    /// - Parameter responder: A responder that was going to be unregistered.
    @objc func unregister(deepLinkResponder responder: OptimoveDeepLinkResponder)
}
