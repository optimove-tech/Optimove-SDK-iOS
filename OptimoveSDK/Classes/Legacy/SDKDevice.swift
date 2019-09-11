//  Copyright © 2019 Optimove. All rights reserved.

import WebKit
import OptimoveCore

struct SDKDevice {

    static var uuid: String {
        return UIDevice.current.identifierForVendor?.uuidString.sha1() ?? ""
    }

    private static let webView = WKWebView(frame: .zero)

    static func evaluateUserAgent(completion: @escaping (String) -> Void) {
        DispatchQueue.main.async {
            webView.evaluateJavaScript("navigator.userAgent") { (result, error) in
                if let error = error {
                    Logger.error(error.localizedDescription)
                }
                completion((result as? String) ?? "user_agent_placeholder")
            }
        }
    }

}
