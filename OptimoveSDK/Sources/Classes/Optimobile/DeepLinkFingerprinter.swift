//  Copyright © 2022 Optimove. All rights reserved.

import Foundation
import WebKit

private enum PrintDustMessage: String {
    case clientReady = "READY"
    case clientFingerprintGeneraged = "FINGERPRINT_GENERATED"
    case requestFingerprint = "REQUEST_FINGERPRINT"
}

private enum DeferredState<R> {
    case pending
    case resolved(R)
}

private class Deferred<R> {
    var state: DeferredState<R>
    var pendingWatchers: [(R) -> Void]

    init() {
        state = .pending
        pendingWatchers = []
    }

    func resolve(result: R) {
        DispatchQueue.main.async {
            switch self.state {
            case .resolved: return
            default: break
            }

            self.state = DeferredState.resolved(result)

            self.pendingWatchers.forEach { cb in
                cb(result)
            }

            self.pendingWatchers.removeAll()
        }
    }

    func then(onResult: @escaping (R) -> Void) {
        DispatchQueue.main.async {
            switch self.state {
            case .pending:
                self.pendingWatchers.append(onResult)
            case let .resolved(result):
                onResult(result)
            }
        }
    }
}

class DeepLinkFingerprinter: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
    fileprivate static let printDustRuntimeUrl = "https://pd.app.delivery"
    fileprivate static let printDustHandlerName = "printHandler"

    fileprivate var webView: WKWebView?
    fileprivate let fingerprint: Deferred<[String: String]>

    override init() {
        let controller = WKUserContentController()
        let config = WKWebViewConfiguration()
        config.userContentController = controller

        webView = WKWebView(frame: UIScreen.main.bounds, configuration: config)
        fingerprint = Deferred()

        super.init()

        controller.add(self, name: DeepLinkFingerprinter.printDustHandlerName)

        let request = URLRequest(url: URL(string: DeepLinkFingerprinter.printDustRuntimeUrl)!, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 10)
        webView?.load(request)
    }

    func getFingerprintComponents(_ onGenerated: @escaping ([String: String]) -> Void) {
        fingerprint.then(onResult: onGenerated)
    }

    func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name != DeepLinkFingerprinter.printDustHandlerName {
            return
        }

        let body = message.body as! NSDictionary
        let type = body["type"] as! String

        switch type {
        case PrintDustMessage.clientReady.rawValue:
            postClientMessage(type: PrintDustMessage.requestFingerprint.rawValue, data: nil)
        case PrintDustMessage.clientFingerprintGeneraged.rawValue:
            guard let data = body["data"] as? [String: AnyObject],
                  let components = data["components"] as? [String: String]
            else {
                return
            }
            fingerprint.resolve(result: components)
            DispatchQueue.main.async { self.cleanUpWebView() }
        default:
            print("Unhandled message: \(type)")
        }
    }

    func webView(_: WKWebView, didFail _: WKNavigation!, withError _: Error) {
        DispatchQueue.main.async { self.cleanUpWebView() }
    }

    fileprivate func postClientMessage(type: String, data: Any?) {
        do {
            let msg: [String: Any] = ["type": type, "data": data != nil ? data! : NSNull()]
            let json: Data = try JSONSerialization.data(withJSONObject: msg, options: JSONSerialization.WritingOptions(rawValue: 0))

            let jsonMsg = String(data: json, encoding: .utf8)
            let evalString = String(format: "postHostMessage(%@);", jsonMsg!)

            webView?.evaluateJavaScript(evalString, completionHandler: nil)
        } catch {
            // Noop
        }
    }

    fileprivate func cleanUpWebView() {
        webView?.stopLoading()
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: DeepLinkFingerprinter.printDustHandlerName)
        webView = nil
    }
}
