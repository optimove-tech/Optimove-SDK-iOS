//  Copyright © 2022 Optimove. All rights reserved.

import StoreKit
import UIKit
import UserNotifications
import WebKit

enum InAppAction: String {
    case CLOSE_MESSAGE = "closeMessage"
    case TRACK_EVENT = "trackConversionEvent"
    case PROMPT_PUSH_PERMISSION = "promptPushPermission"
    case OPEN_URL = "openUrl"
    case DEEP_LINK = "deepLink"
    case REQUEST_RATING = "requestAppStoreRating"
}

final class InAppPresenter: NSObject, WKScriptMessageHandler, WKNavigationDelegate {

    private var webView: WKWebView?
    private var loadingSpinner: UIActivityIndicatorView?
    private var frame: UIView?
    private var window: UIWindow?
    private var webViewReady = false
    private var interceptionInProgress = false

    private var contentController: WKUserContentController?

    private var messageQueue: NSMutableOrderedSet
    private var pendingTickleIds: NSMutableOrderedSet

    private var displayMode: InAppDisplayMode
    private var currentMessage: InAppMessage?

    let urlBuilder: UrlBuilder

    private class InterceptionDecision: InAppMessageInterceptorDecision {
        private var resolved: Bool = false
        private let onShow: () -> Void
        private let onSuppress: () -> Void
        private var cancelTimeout: (() -> Void)?

        init(onShow: @escaping () -> Void, onSuppress: @escaping () -> Void) {
            self.onShow = onShow
            self.onSuppress = onSuppress
        }

        func setCancelTimeout(_ cancel: @escaping () -> Void) {
            self.cancelTimeout = cancel
        }

        func show() {
            DispatchQueue.main.async {
                guard !self.resolved else { return }
                self.resolved = true
                self.cancelTimeout?()
                self.onShow()
            }
        }

        func suppress() {
            DispatchQueue.main.async {
                guard !self.resolved else { return }
                self.resolved = true
                self.cancelTimeout?()
                self.onSuppress()
            }
        }
    }

    init(displayMode: InAppDisplayMode, urlBuilder: UrlBuilder) {
        messageQueue = NSMutableOrderedSet(capacity: 5)
        pendingTickleIds = NSMutableOrderedSet(capacity: 2)
        currentMessage = nil

        self.displayMode = displayMode
        self.urlBuilder = urlBuilder

        super.init()
    }

    func setDisplayMode(_ mode: InAppDisplayMode) {
        ensureMain {
            let resumed = mode != self.displayMode && mode != .paused
            self.displayMode = mode
            if resumed { self.presentFromQueue() }
        }
    }

    func getDisplayMode() -> InAppDisplayMode {
        return displayMode
    }

    func queueMessagesForPresentation(messages: [InAppMessage], tickleIds: NSOrderedSet) {
        ensureMain { self.queueMessagesForPresentation_onMain(messages: messages, tickleIds: tickleIds) }
    }

    private func queueMessagesForPresentation_onMain(messages: [InAppMessage], tickleIds: NSOrderedSet) {
        assertOnMainThread()

        if messages.count == 0 && messageQueue.count == 0 {
            return
        }

        for message in messages {
            if messageQueue.contains(message) {
                continue
            }
            messageQueue.add(message)
        }

        for tickleId in tickleIds {
            if pendingTickleIds.contains(tickleId) {
                continue
            }
            pendingTickleIds.insert(tickleId, at: 0)

            messageQueue.sort { a, b -> ComparisonResult in
                guard let a = a as? InAppMessage, let b = b as? InAppMessage else {
                    return .orderedSame
                }

                let aIsTickle = self.pendingTickleIds.contains(a.id)
                let bIsTickle = self.pendingTickleIds.contains(b.id)

                if aIsTickle, !bIsTickle {
                    return .orderedAscending
                } else if !aIsTickle, bIsTickle {
                    return .orderedDescending
                } else if aIsTickle, bIsTickle {
                    let aIdx = self.pendingTickleIds.index(of: a.id)
                    let bIdx = self.pendingTickleIds.index(of: b.id)

                    if aIdx < bIdx {
                        return .orderedAscending
                    } else if aIdx > bIdx {
                        return .orderedDescending
                    }
                }

                return .orderedSame
            }
        }

        let notShowingCurrentTickle = currentMessage != nil
            && messageQueue.count > 0
            && currentMessage!.id != (messageQueue[0] as! InAppMessage).id
            && (messageQueue[0] as! InAppMessage).id == pendingTickleIds.firstObject as? Int64

        let queueNotEmptyAndNotShowingAnything = currentMessage == nil && messageQueue.count > 0

        let shouldShowSomething = notShowingCurrentTickle || queueNotEmptyAndNotShowingAnything

        if shouldShowSomething {
            presentFromQueue_onMain()
        }
    }

    func presentFromQueue() {
        ensureMain { self.presentFromQueue_onMain() }
    }

    private func presentFromQueue_onMain() {
        assertOnMainThread()

        if messageQueue.count == 0 || displayMode == .paused {
            self.destroyViews()
            return
        }

        let head = (messageQueue[0] as! InAppMessage)

        if interceptionInProgress {
            return
        }

        if let interceptor = OptimoveInApp.getInAppMessageInterceptor(), currentMessage?.id != head.id {
            interceptionInProgress = true
            applyMessageInterception(head, interceptor: interceptor)
            return
        }

        initViews()
        self.loadingSpinner?.startAnimating()

        guard self.webViewReady else {
            return
        }

        showMessage(head)
    }

    func handleMessageClosed() {
        assertOnMainThread()
        guard let message = currentMessage else {
            return
        }

        messageQueue.removeObject(at: 0)
        cleanupMessageAndAdvance(message)
    }

    func cancelCurrentPresentationQueue(waitForViewCleanup: Bool) {
        ensureMain { self.cancelCurrentPresentationQueue_onMain(waitForViewCleanup: waitForViewCleanup) }
    }

    private func cancelCurrentPresentationQueue_onMain(waitForViewCleanup: Bool) {
        assertOnMainThread()

        messageQueue.removeAllObjects()
        pendingTickleIds.removeAllObjects()
        currentMessage = nil

        if waitForViewCleanup == true {
            self.destroyViews()
        } else {
            self.destroyViews()
        }
    }

    func initViews() {
        if window != nil {
            return
        }

        // Window / frame setup
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

        // Webview
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
            // Allow content to pass under the notch / home button
            webView.scrollView.contentInsetAdjustmentBehavior = .never
        }

        frame.addSubview(webView)

        #if DEBUG
            let cachePolicy = URLRequest.CachePolicy.useProtocolCachePolicy
        #else
            let cachePolicy = URLRequest.CachePolicy.reloadIgnoringCacheData
        #endif
        if let url = try? urlBuilder.urlForService(.iar) {
            let request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: 8)
            webView.load(request)
        }

        // Spinner
        let loadingSpinner = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
        self.loadingSpinner = loadingSpinner

        loadingSpinner.translatesAutoresizingMaskIntoConstraints = true
        loadingSpinner.hidesWhenStopped = true
        loadingSpinner.startAnimating()

        frame.addSubview(loadingSpinner)

        loadingSpinner.center = frame.center
        frame.bringSubviewToFront(loadingSpinner)
    }

    // Expects to be called from the main thread
    func destroyViews() {
        if let window = window {
            window.isHidden = true

            if let spinner = loadingSpinner {
                spinner.removeFromSuperview()
                loadingSpinner = nil
            }

            if let webView = webView {
                webView.removeFromSuperview()
                self.webView = nil
            }

            if let frame = frame {
                frame.removeFromSuperview()
                self.frame = nil
            }
        }

        window = nil
        webViewReady = false
    }

    func postClientMessage(type: String, data: Any?) {
        assertOnMainThread()
        guard let webView = webView else {
            return
        }

        do {
            let msg: [String: Any] = ["type": type, "data": data != nil ? data! : NSNull()]
            let json: Data = try JSONSerialization.data(withJSONObject: msg, options: [])

            let jsonMsg = String(data: json, encoding: .utf8)
            let evalString = String(format: "postHostMessage(%@);", jsonMsg!)

            webView.evaluateJavaScript(evalString, completionHandler: nil)
        } catch {
            Logger.error(error.localizedDescription)
        }
    }

    func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name != "inAppHost" {
            return
        }

        let body = message.body as! NSDictionary
        let type = body["type"] as! String

        if type == "READY" {
            self.webViewReady = true

            presentFromQueue_onMain()
        } else if type == "MESSAGE_OPENED" {
            loadingSpinner?.stopAnimating()
            Optimobile.sharedInstance.inAppManager.handleMessageOpened(message: currentMessage!)
        } else if type == "MESSAGE_CLOSED" {
            handleMessageClosed()
        } else if type == "EXECUTE_ACTIONS" {
            guard let body = message.body as? [AnyHashable: Any],
                  let data = body["data"] as? [AnyHashable: Any],
                  let actions = data["actions"] as? [NSDictionary]
            else {
                return
            }
            handleActions(actions: actions)
        } else {
            print("Unknown message: \(message.body)")
        }
    }

    func webView(_: WKWebView, didFinish _: WKNavigation!) {
        // Noop
    }

    func webView(_: WKWebView, didFail _: WKNavigation!, withError _: Error) {
        // Handles transfer errors after starting load
        cancelCurrentPresentationQueue_onMain(waitForViewCleanup: false)
    }

    func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError _: Error) {
        // Handles connection/timeout errors for the main frame load
        cancelCurrentPresentationQueue_onMain(waitForViewCleanup: false)
    }

    func webView(_: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        // Handles HTTP responses for all status codes
        if let httpResponse = navigationResponse.response as? HTTPURLResponse,
           let url = httpResponse.url,
           let baseUrl = try? urlBuilder.urlForService(.iar)
        {
            if url.absoluteString.starts(with: baseUrl.absoluteString), httpResponse.statusCode >= 400 {
                decisionHandler(.cancel)
                cancelCurrentPresentationQueue_onMain(waitForViewCleanup: false)
                return
            }
        }

        decisionHandler(.allow)
    }

    func webViewWebContentProcessDidTerminate(_: WKWebView) {
        cancelCurrentPresentationQueue_onMain(waitForViewCleanup: false)
    }

    func handleActions(actions: [NSDictionary]) {
        if let message = currentMessage {
            var hasClose = false
            var conversionEvent: String?
            var conversionEventData: [String: Any]?
            var userAction: NSDictionary?

            for action in actions {
                let type = InAppAction(rawValue: action["type"] as! String)!
                let data = action["data"] as? [AnyHashable: Any]

                switch type {
                case .CLOSE_MESSAGE:
                    hasClose = true
                case .TRACK_EVENT:
                    conversionEvent = data?["eventType"] as? String
                    conversionEventData = data?["data"] as? [String: Any]
                default:
                    userAction = action
                }
            }

            if hasClose {
                Optimobile.sharedInstance.inAppManager.markMessageDismissed(message: message)
                postClientMessage(type: "CLOSE_MESSAGE", data: nil)
            }

            if let conversionEvent = conversionEvent {
                Optimobile.trackEventImmediately(eventType: conversionEvent, properties: conversionEventData)
            }

            if userAction != nil {
                handleUserAction(message: message, userAction: userAction!)
                cancelCurrentPresentationQueue(waitForViewCleanup: true)
            }
        }
    }

    private func showMessage(_ message: InAppMessage) {
        assertOnMainThread()

        currentMessage = message

        let content = NSMutableDictionary(dictionary: message.content)
        content["region"] = Optimobile.sharedInstance.config.region.rawValue

        postClientMessage(type: "PRESENT_MESSAGE", data: content)
    }

    private func applyMessageInterception(_ message: InAppMessage, interceptor: InAppMessageInterceptor) {
        assertOnMainThread()

        let decision = InterceptionDecision(
            onShow: { [weak self] in
                self?.handleShowDecision(for: message)
            },
            onSuppress: { [weak self] in
                self?.handleSuppressDecision(for: message)
            }
        )

        let timeoutMs = max(0, interceptor.getTimeoutMs())
        let timeoutItem = DispatchWorkItem { [weak decision] in
            decision?.suppress()
        }

        decision.setCancelTimeout {
            timeoutItem.cancel()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(timeoutMs), execute: timeoutItem)

        let data = message.data as? [String: Any]
        
        do {
            interceptor.processMessage(data: data, decision: decision)
        } catch {
            Logger.error("Error in message interceptor: \(error.localizedDescription)")
            decision.suppress()
        }
    }

    private func handleShowDecision(for message: InAppMessage) {
        assertOnMainThread()

        currentMessage = message
        interceptionInProgress = false

        initViews()
        loadingSpinner?.startAnimating()
        if webViewReady {
            showMessage(message)
        }
    }

    private func handleSuppressDecision(for message: InAppMessage) {
        assertOnMainThread()

        interceptionInProgress = false

        Optimobile.sharedInstance.inAppManager.markMessageDismissed(message: message)

        let idx = messageQueue.index(of: message)
        if idx != NSNotFound {
            messageQueue.removeObject(at: idx)
        }

        cleanupMessageAndAdvance(message)
    }

    private func cleanupMessageAndAdvance(_ message: InAppMessage) {
        assertOnMainThread()

        if #available(iOS 10, *) {
            let tickleNotificationId = "k-in-app-message:\(message.id)"
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [tickleNotificationId])
            PendingNotificationHelper.remove(identifier: tickleNotificationId)
        }

        pendingTickleIds.remove(message.id)
        currentMessage = nil

        if messageQueue.count == 0 {
            pendingTickleIds.removeAllObjects()
        }

        presentFromQueue_onMain()
    }

    func handleUserAction(message: InAppMessage, userAction: NSDictionary) {
        let type = userAction["type"] as! String

        if type == InAppAction.PROMPT_PUSH_PERMISSION.rawValue {
            Optimobile.pushRequestDeviceToken()
        } else if type == InAppAction.DEEP_LINK.rawValue {
            if Optimobile.sharedInstance.config.inAppDeepLinkHandlerBlock == nil {
                return
            }
            DispatchQueue.main.async {
                let data = userAction.value(forKeyPath: "data.deepLink") as? [AnyHashable: Any] ?? [:]
                let buttonPress = InAppButtonPress(deepLinkData: data, messageId: message.id, messageData: message.data)
                Optimobile.sharedInstance.config.inAppDeepLinkHandlerBlock?(buttonPress)
            }
        } else if type == InAppAction.OPEN_URL.rawValue {
            guard let url = URL(string: userAction.value(forKeyPath: "data.url") as! String) else {
                return
            }

            if #available(iOS 10.0.0, *) {
                UIApplication.shared.open(url, options: [:]) { _ in
                    // noop
                }
            } else {
                DispatchQueue.main.async {
                    UIApplication.shared.openURL(url)
                }
            }
        } else if type == InAppAction.REQUEST_RATING.rawValue {
            if #available(iOS 10.3.0, *) {
                SKStoreReviewController.requestReview()
            } else {
                NSLog("Requesting a rating not supported on this iOS version")
            }
        }
    }

    private func ensureMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    private func assertOnMainThread(_ message: String = "Must be on main thread") {
        assert(Thread.isMainThread, message)
    }
}
