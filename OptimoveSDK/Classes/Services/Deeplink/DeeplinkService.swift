//  Copyright © 2019 Optimove. All rights reserved.

final class DeeplinkService {

    private var deepLinkResponders = [OptimoveDeepLinkResponder]()
    private var deepLinkComponents: OptimoveDeepLinkComponents? = nil

    func setDeepLinkComponents(_ component: OptimoveDeepLinkComponents) {
        self.deepLinkComponents = component
        deepLinkResponders.forEach { responder in
            responder.didReceive(deepLinkComponent: component)
        }
    }

}

extension DeeplinkService: OptimoveDeepLinkResponding {

    func register(deepLinkResponder responder: OptimoveDeepLinkResponder) {
        if let deepLinkComponents = deepLinkComponents {
            responder.didReceive(deepLinkComponent: deepLinkComponents)
        } else {
            deepLinkResponders.append(responder)
        }
    }

    func unregister(deepLinkResponder responder: OptimoveDeepLinkResponder) {
        if let index = self.deepLinkResponders.firstIndex(of: responder) {
            deepLinkResponders.remove(at: index)
        }
    }

}
