//  Copyright © 2025 Optimove. All rights reserved.

import UIKit
import WebKit

protocol OverlayMessagingPresenterDelegate: AnyObject {
    func onMessageClosed(_ message: OverlayMessagingMessage)
    func onEvents(_ message: OverlayMessagingMessage, events: [OverlayMessagingRendererEvent])
func onViewError(_ message: OverlayMessagingMessage)
}

final class OverlayMessagingPresenter: NSObject, WKScriptMessageHandler, WKNavigationDelegate {

    private static let sdkActionOpenDeepLink = "OPEN_DEEP_LINK"

    private var webView: WKWebView?
    private var loadingSpinner: UIActivityIndicatorView?
    private var frame: UIView?
    private var window: UIWindow?
    private var webViewReady = false

    private var contentController: WKUserContentController?

    private var currentMessage: OverlayMessagingMessage
    private weak var delegate: OverlayMessagingPresenterDelegate?
    private let urlBuilder: UrlBuilder

    init(message: OverlayMessagingMessage, urlBuilder: UrlBuilder, delegate: OverlayMessagingPresenterDelegate) {
        self.currentMessage = message
        self.urlBuilder = urlBuilder
        self.delegate = delegate
        super.init()
        initViews()
    }

    func showMessage(_ message: OverlayMessagingMessage) {
        guard message.id != currentMessage.id else { return }
        currentMessage = message
        sendCurrentMessageToClient()
    }

    func dispose() {
        destroyViews()
    }

    // MARK: - View lifecycle

    private func initViews() {
        guard let url = try? urlBuilder.urlForService(.iar) else {
            Logger.error("Failed to resolve IAR service URL, deferring overlay messaging presentation")
            return
        }
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.windowLevel = UIWindow.Level.alert
        window!.rootViewController = UIViewController()

        #if swift(>=5.1)
            if #available(iOS 13.0, *) {
                window?.windowScene = UIApplication.shared
                    .connectedScenes
                    .first as? UIWindowScene
            }
        #endif

        let frame = UIView(frame: window!.frame)
        self.frame = frame
        frame.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        frame.backgroundColor = .clear

        window!.isHidden = false
        window!.rootViewController!.view = frame

        contentController = WKUserContentController()
        contentController!.add(self, name: "inAppHost")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController!
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        #if DEBUG
            config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        #endif

        let webView = WKWebView(frame: window!.frame, configuration: config)
        self.webView = webView

        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.isOpaque = false
        webView.navigationDelegate = self
        webView.scrollView.bounces = false
        webView.scrollView.isScrollEnabled = false
        webView.allowsBackForwardNavigationGestures = false

        if #available(iOS 9.0, *) {
            webView.allowsLinkPreview = false
        }

        if #available(iOS 11.0.0, *) {
            webView.scrollView.contentInsetAdjustmentBehavior = .never
        }

        frame.addSubview(webView)

        #if DEBUG
            let cachePolicy = URLRequest.CachePolicy.useProtocolCachePolicy
        #else
            let cachePolicy = URLRequest.CachePolicy.reloadIgnoringCacheData
        #endif
        let request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: 8)
        webView.load(request)

        let loadingSpinner = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
        self.loadingSpinner = loadingSpinner
        loadingSpinner.translatesAutoresizingMaskIntoConstraints = true
        loadingSpinner.hidesWhenStopped = true
        loadingSpinner.startAnimating()

        frame.addSubview(loadingSpinner)
        loadingSpinner.center = frame.center
        frame.bringSubviewToFront(loadingSpinner)
    }

    private func destroyViews() {
        if let window = window {
            window.isHidden = true

            loadingSpinner?.removeFromSuperview()
            loadingSpinner = nil

            webView?.removeFromSuperview()
            webView = nil

            frame?.removeFromSuperview()
            frame = nil
        }

        window = nil
        webViewReady = false
    }

    // MARK: - Client messaging

    private func sendCurrentMessageToClient() {
        guard webViewReady else { return }

        let content = NSMutableDictionary(dictionary: currentMessage.content)

        postClientMessage(type: "PRESENT_MESSAGE", data: content)
    }

    private func postClientMessage(type: String, data: Any?) {
        guard let webView = webView else { return }

        do {
            let msg: [String: Any] = ["type": type, "data": data != nil ? data! : NSNull()]
            let json = try JSONSerialization.data(withJSONObject: msg, options: [])
            let jsonMsg = String(data: json, encoding: .utf8)!
            let evalString = String(format: "postHostMessage(%@);", jsonMsg)
            webView.evaluateJavaScript(evalString, completionHandler: nil)
        } catch {
            Logger.error(error.localizedDescription)
        }
    }
    

    // MARK: - WKScriptMessageHandler

    func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "inAppHost",
              let body = message.body as? NSDictionary,
              let type = body["type"] as? String
        else { return }

        switch type {
        case "READY":
            webViewReady = true
            sendCurrentMessageToClient()
        case "MESSAGE_OPENED":
            loadingSpinner?.stopAnimating()
        case "MESSAGE_CLOSED":
            delegate?.onMessageClosed(currentMessage)
        case "COMMAND":
            handleCommand(body["data"])
        case "PRESENTATION_ERROR":
            delegate?.onViewError(currentMessage)
        default:
            break
        }
    }

    // MARK: - WKNavigationDelegate

    func webView(_: WKWebView, didFail _: WKNavigation!, withError _: Error) {
        delegate?.onViewError(currentMessage)
    }

    func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError _: Error) {
        delegate?.onViewError(currentMessage)
    }

    func webView(_: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let httpResponse = navigationResponse.response as? HTTPURLResponse,
           let url = httpResponse.url,
           let baseUrl = try? urlBuilder.urlForService(.iar)
        {
            if url.absoluteString.starts(with: baseUrl.absoluteString), httpResponse.statusCode >= 400 {
                decisionHandler(.cancel)
                delegate?.onViewError(currentMessage)
                return
            }
        }
        decisionHandler(.allow)
    }

    func webViewWebContentProcessDidTerminate(_: WKWebView) {
        delegate?.onViewError(currentMessage)
    }

    // MARK: - COMMAND handling

    private func handleCommand(_ rawData: Any?) {
        guard let data = rawData as? NSDictionary else { return }

        let events = OverlayMessagingRendererEvent.parseAll(from: data["events"] as? [Any])
        let close = data["close"] as? Bool ?? false
        let sdkActions = data["executeSdkActions"] as? [Any]

        if !events.isEmpty {
            delegate?.onEvents(currentMessage, events: events)
        }

        if close {
            postClientMessage(type: "CLOSE_MESSAGE", data: nil)
        }

        if let sdkActions = sdkActions {
            handleSdkActions(sdkActions)
        }
    }

    private func handleSdkActions(_ actions: [Any]) {
        for item in actions {
            guard let action = item as? NSDictionary,
                  let type = action["type"] as? String
            else { continue }

            switch type {
            case Self.sdkActionOpenDeepLink:
                if let actionData = action["data"] as? NSDictionary,
                   let urlString = actionData["url"] as? String,
                   let url = URL(string: urlString)
                {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    } else {
                        UIApplication.shared.openURL(url)
                    }
                }
            default:
                break
            }
        }
    }
}
