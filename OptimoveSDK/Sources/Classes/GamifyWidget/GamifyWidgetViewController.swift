//  Copyright © 2026 Optimove. All rights reserved.

import UIKit
import WebKit

private enum BridgeMessage {
    static let receiveMessage = "receiveMessage"
    static let closeWidget = "closeWidget"
}

final class GamifyWidgetViewController: UIViewController {

    private let widgetUrl: String
    private let userId: String?
    private let token: String?

    private var webView: WKWebView!
    private var activityIndicator: UIActivityIndicatorView!

    init(widgetUrl: String, userId: String?, token: String?) {
        self.widgetUrl = widgetUrl
        self.userId = userId
        self.token = token
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        setupWebView()
        setupLoadingIndicator()
        loadWidget()
    }

    private func setupWebView() {
        let contentController = WKUserContentController()
        contentController.add(self, name: BridgeMessage.receiveMessage)
        contentController.add(self, name: BridgeMessage.closeWidget)

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func setupLoadingIndicator() {
        if #available(iOS 13.0, *) {
            activityIndicator = UIActivityIndicatorView(style: .medium)
        } else {
            activityIndicator = UIActivityIndicatorView(style: .gray)
        }
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        activityIndicator.startAnimating()
    }

    private func loadWidget() {
        guard let url = URL(string: widgetUrl) else {
            dismissSelf()
            return
        }
        webView.load(URLRequest(url: url))
    }

    private func sendInit() {
        var payload: [String: Any] = ["type": "INIT"]
        if let userId = userId { payload["userId"] = userId }
        if let token = token { payload["token"] = token }
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let json = String(data: data, encoding: .utf8) else { return }
        Logger.debug("GamifyWidget sending INIT: \(redactedLog(payload))")
        webView.evaluateJavaScript("window.postMessage(\(json), '*');", completionHandler: nil)
    }

    private func redactedLog(_ payload: [String: Any]) -> String {
        var redacted = payload
        if redacted["token"] != nil { redacted["token"] = "[REDACTED]" }
        return "\(redacted)"
    }

    private func dismissSelf() {
        dismiss(animated: true)
    }
}

extension GamifyWidgetViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == BridgeMessage.closeWidget {
            DispatchQueue.main.async { self.dismissSelf() }
            return
        }
        guard message.name == BridgeMessage.receiveMessage,
              let body = message.body as? [String: Any],
              let type = body["type"] as? String else { return }
        if type == "READY" {
            DispatchQueue.main.async { self.sendInit() }
        }
    }
}

extension GamifyWidgetViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }

    func webView(_: WKWebView, didFail _: WKNavigation!, withError _: Error) {
        dismissSelf()
    }

    func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError _: Error) {
        dismissSelf()
    }
}
