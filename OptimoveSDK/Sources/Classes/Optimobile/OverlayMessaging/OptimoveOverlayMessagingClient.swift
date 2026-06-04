//  Copyright © 2025 Optimove. All rights reserved.

import Foundation

public struct OptimoveOverlayMessagingClient {

    public func setActionHandler(_ type: OverlayActionType, _ handler: OverlayActionHandler?) {
        OptimoveOverlayMessaging.setActionHandler(type, handler)
    }

    public func setInterceptor(_ interceptor: OverlayMessagingInterceptor?) {
        OptimoveOverlayMessaging.setInterceptor(interceptor)
    }

    public func resetSession() {
        OptimoveOverlayMessaging.resetSession()
    }
}
