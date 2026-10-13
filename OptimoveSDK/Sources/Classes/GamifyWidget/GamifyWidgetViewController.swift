//  Copyright © 2026 Optimove. All rights reserved.

import UIKit
import WebKit

private enum BridgeMessage {
    static let receiveMessage = "receiveMessage"
    static let closeWidget = "closeWidget"
}

final class GamifyWidgetViewController: UIViewController {

    /// Supplies the token for the loyalty INIT; the completion may be invoked on any queue.
    typealias TokenSource = (_ completion: @escaping (Result<String?, Error>) -> Void) -> Void

    private let widgetUrl: String
    private let userId: String?
    private let tokenSource: TokenSource?
    private var handshake: LoyaltyInitHandshake?

    private var webView: WKWebView!
    private var activityIndicator: UIActivityIndicatorView!
    private var dismissWhenPresented = false

    /// Loyalty widget — READY→INIT handshake with optional userId and the token from `tokenSource`.
    convenience init(widgetUrl: String, userId: String?, tokenSource: @escaping TokenSource) {
        self.init(widgetUrl: widgetUrl, userId: userId, tokenSource: tokenSource, enableInitHandshake: true)
    }

    /// Adact campaign — no INIT handshake; identity is passed via URL query params.
    convenience init(widgetUrl: String) {
        self.init(widgetUrl: widgetUrl, userId: nil, tokenSource: nil, enableInitHandshake: false)
    }

    private init(widgetUrl: String, userId: String?, tokenSource: TokenSource?, enableInitHandshake: Bool) {
        self.widgetUrl = widgetUrl
        self.userId = userId
        self.tokenSource = tokenSource
        super.init(nibName: nil, bundle: nil)
        if enableInitHandshake {
            handshake = LoyaltyInitHandshake(
                sendInit: { [weak self] token in self?.sendInit(token: token) },
                onTokenFailed: { [weak self] error in
                    Logger.error("Auth token unavailable for loyalty widget, closing: \(error.localizedDescription)")
                    self?.dismissSelf()
                }
            )
        }
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
        fetchToken()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // isBeingPresented is still true here, so dismiss directly rather than via dismissSelf().
        if dismissWhenPresented {
            dismissWhenPresented = false
            dismiss(animated: true)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed {
            handshake?.cancel()
        }
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

    private func fetchToken() {
        guard let handshake = handshake, let tokenSource = tokenSource else { return }
        tokenSource { result in
            DispatchQueue.main.async { handshake.onTokenResult(result) }
        }
    }

    private func sendInit(token: String?) {
        guard webView != nil else { return }
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
        handshake?.cancel()
        if isBeingPresented {
            dismissWhenPresented = true
            return
        }
        dismiss(animated: true)
    }

    private func parseMessageBody(_ body: Any) -> [String: Any]? {
        if let dict = body as? [String: Any] {
            return dict
        }
        if let string = body as? String,
           let data = string.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return dict
        }
        return nil
    }
}

extension GamifyWidgetViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == BridgeMessage.closeWidget {
            DispatchQueue.main.async { self.dismissSelf() }
            return
        }
        guard message.name == BridgeMessage.receiveMessage,
              let body = parseMessageBody(message.body),
              let type = body["type"] as? String else { return }

        switch type {
        case "READY":
            guard let handshake = handshake else { return }
            DispatchQueue.main.async { handshake.onReady() }
        case "CLOSE":
            DispatchQueue.main.async { self.dismissSelf() }
        default:
            break
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
