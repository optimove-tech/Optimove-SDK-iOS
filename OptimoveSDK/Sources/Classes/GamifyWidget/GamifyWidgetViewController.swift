// Copyright © 2024 Optimove. All rights reserved.

import UIKit
import WebKit

private enum BridgeMessage {
    static let handlerName = "nativeBridge"
}

final class GamifyWidgetViewController: UIViewController {

    private let widgetUrl: String
    private let userId: String?
    private let token: String?

    private var webView: WKWebView!
    private var activityIndicator: UIActivityIndicatorView!
    private var errorLabel: UILabel!

    init(widgetUrl: String, userId: String?, token: String?) {
        self.widgetUrl = widgetUrl
        self.userId = userId
        self.token = token
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupWebView()
        setupLoadingIndicator()
        setupErrorLabel()
        loadWidget()
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(dismissSelf)
        )
    }

    private func setupWebView() {
        let contentController = WKUserContentController()
        contentController.add(self, name: BridgeMessage.handlerName)

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
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupLoadingIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        activityIndicator.startAnimating()
    }

    private func setupErrorLabel() {
        errorLabel = UILabel()
        errorLabel.text = "Unable to load widget.\nCheck your connection and try again."
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        errorLabel.isHidden = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(errorLabel)
        NSLayoutConstraint.activate([
            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
    }

    private func loadWidget() {
        guard let url = URL(string: widgetUrl) else {
            showError()
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

    private func showError() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.webView.isHidden = true
            self.errorLabel.isHidden = false
        }
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
}

extension GamifyWidgetViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == BridgeMessage.handlerName,
              let body = message.body as? [String: Any],
              let type = body["type"] as? String else { return }

        if type == "READY" {
            DispatchQueue.main.async { self.sendInit() }
        } else if type == "CLOSE" {
            DispatchQueue.main.async { self.dismissSelf() }
        }
    }
}

extension GamifyWidgetViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showError()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showError()
    }
}
