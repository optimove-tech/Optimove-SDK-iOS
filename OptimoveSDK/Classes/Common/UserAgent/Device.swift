import UIKit.UIWebView

struct Device {

    static var uuid: String {
        return UIDevice.current.identifierForVendor?.uuidString.sha1() ?? ""
    }
    static func evaluateUserAgent() -> String {
        let webView = UIWebView(frame: .zero)
        return webView.stringByEvaluatingJavaScript(from: "navigator.userAgent") ?? ""
    }

}
