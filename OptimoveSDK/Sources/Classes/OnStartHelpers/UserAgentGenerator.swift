//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore
import WebKit

final class UserAgentGenerator {

    private var storage: OptimoveStorage
    private let synchronizer: Synchronizer
    private let coreEventFactory: CoreEventFactory
    private var webView: WKWebView?

    init(storage: OptimoveStorage,
         synchronizer: Synchronizer,
         coreEventFactory: CoreEventFactory) {
        self.storage = storage
        self.synchronizer = synchronizer
        self.coreEventFactory = coreEventFactory
    }

    func generate() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.generate()
            }
            return
        }
        webView = WKWebView(frame: .zero)
        webView?.evaluateJavaScript("navigator.userAgent") { (result, error) in
            if let error = error {
                Logger.error(error.localizedDescription)
            }
            self.storage.userAgent = (result as? String) ?? "user_agent_undefined"
            tryCatch {
                let event = try self.coreEventFactory.createEvent(.setUserAgent)
                self.synchronizer.handle(.report(events: [event]))
            }
            self.webView = nil
        }
    }

}
