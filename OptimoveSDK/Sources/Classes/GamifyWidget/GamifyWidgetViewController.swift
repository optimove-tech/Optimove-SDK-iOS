//  Copyright © 2026 Optimove. All rights reserved.

import UIKit
import WebKit

private enum BridgeMessage {
    static let receiveMessage = "receiveMessage"
    static let closeWidget = "closeWidget"
}

final class GamifyWidgetViewController: UIViewController {

    /// Supplies the token for the loyalty INIT and TOKEN_REFRESHED replies; the completion may be invoked on any queue.
    typealias TokenSource = (_ completion: @escaping (Result<String?, Error>) -> Void) -> Void

    private let widgetUrl: String
    private let widgetOrigin: String?
    private let userId: String?
    private let tokenSource: TokenSource?
    private var handshake: LoyaltyInitHandshake?

    private var webView: WKWebView!
    private var activityIndicator: UIActivityIndicatorView!
    private var dismissWhenPresented = false
    private var isClosed = false
    private var refreshInFlight = false

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
        self.widgetOrigin = URL(string: widgetUrl).flatMap(Self.origin(of:))
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
            isClosed = true
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
        var payload: [String: Any] = ["type": "INIT"]
        if let userId = userId { payload["userId"] = userId }
        if let token = token { payload["token"] = token }
        postToWidget(payload)
    }

    /// Fetches a fresh token when the loyalty widget asks for one and posts it back as TOKEN_REFRESHED. A failed fetch
    /// is reported as a `null` token rather than closing the widget.
    /// Requests arriving while a fetch is in flight are dropped; the pending reply answers them.
    private func refreshToken() {
        guard let tokenSource = tokenSource, !isClosed, !refreshInFlight else { return }
        refreshInFlight = true
        tokenSource { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.refreshInFlight = false
                guard !self.isClosed else { return }
                let token: String?
                switch result {
                case let .success(value):
                    token = value
                case let .failure(error):
                    Logger.error("Auth token refresh failed for loyalty widget: \(error.localizedDescription)")
                    token = nil
                }
                self.postToWidget(["type": "TOKEN_REFRESHED", "token": token.map { $0 as Any } ?? NSNull()])
            }
        }
    }

    /// Posts with the widget origin as targetOrigin, so the browser drops the message if the page has left it.
    private func postToWidget(_ payload: [String: Any]) {
        guard webView != nil else { return }
        guard let widgetOrigin = widgetOrigin else {
            Logger.error("Widget URL has no origin, not posting: \(widgetUrl)")
            return
        }
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let json = String(data: data, encoding: .utf8) else { return }
        Logger.debug("GamifyWidget sending \(payload["type"] ?? ""): \(redactedLog(payload))")
        webView.evaluateJavaScript(
            "window.postMessage(\(json), \(Self.jsStringLiteral(widgetOrigin)));",
            completionHandler: nil
        )
    }

    private static func jsStringLiteral(_ value: String) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: [value]),
              let array = String(data: data, encoding: .utf8) else { return "''" }
        return String(array.dropFirst().dropLast())
    }

    /// `scheme://host[:port]` as a browser serializes an origin, or nil for opaque URLs.
    static func origin(of url: URL) -> String? {
        guard let scheme = url.scheme?.lowercased(), let host = url.host?.lowercased(), !host.isEmpty else {
            return nil
        }
        let origin = "\(scheme)://\(host)"
        guard let port = url.port,
              !(scheme == "https" && port == 443),
              !(scheme == "http" && port == 80) else {
            return origin
        }
        return "\(origin):\(port)"
    }

    /// Keeps the loyalty web view on the widget origin: the script message handlers are exposed to every document the
    /// web view loads, so an off-origin page could otherwise request a token. Such navigations go to the system browser.
    /// Adact campaigns have no token bridge and navigate freely.
    private func leavesWidgetOrigin(_ target: URL) -> Bool {
        guard handshake != nil else { return false }
        if let widgetOrigin = widgetOrigin, widgetOrigin == Self.origin(of: target) {
            return false
        }
        Logger.debug("GamifyWidget opening off-origin navigation externally: \(target)")
        UIApplication.shared.open(target, options: [:], completionHandler: nil)
        return true
    }

    private func redactedLog(_ payload: [String: Any]) -> String {
        var redacted = payload
        if let token = redacted["token"], !(token is NSNull) { redacted["token"] = "[REDACTED]" }
        return "\(redacted)"
    }

    private func dismissSelf() {
        isClosed = true
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
        case "REFRESH_TOKEN":
            DispatchQueue.main.async { self.refreshToken() }
        case "CLOSE":
            DispatchQueue.main.async { self.dismissSelf() }
        default:
            break
        }
    }
}

extension GamifyWidgetViewController: WKNavigationDelegate {
    func webView(
        _: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if navigationAction.targetFrame?.isMainFrame == true,
           let url = navigationAction.request.url,
           leavesWidgetOrigin(url) {
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

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
