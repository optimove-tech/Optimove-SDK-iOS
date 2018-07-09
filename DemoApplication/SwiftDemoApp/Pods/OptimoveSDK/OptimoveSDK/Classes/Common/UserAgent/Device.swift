
import UIKit

class Device {
    typealias UserAgent = String
    static func evaluateUserAgent() -> UserAgent
    {
        let webView = UIWebView(frame: .zero)
        return webView.stringByEvaluatingJavaScript(from: "navigator.userAgent") ?? ""
    }
}
