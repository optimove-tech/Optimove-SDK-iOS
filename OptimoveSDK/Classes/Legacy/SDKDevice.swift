//  Copyright © 2019 Optimove. All rights reserved.

import WebKit
import OptimoveCore

struct SDKDevice {

    private static var webView: WKWebView?

    static func evaluateUserAgent(completion: @escaping (String) -> Void) {
        DispatchQueue.main.async {
            webView = WKWebView(frame: .zero)
            webView?.evaluateJavaScript("navigator.userAgent") { (result, error) in
                if let error = error {
                    Logger.error(error.localizedDescription)
                }
                completion((result as? String) ?? "user_agent_placeholder")
                webView = nil
            }
        }
    }

}
