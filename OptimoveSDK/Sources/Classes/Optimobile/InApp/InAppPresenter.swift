//  Copyright © 2022 Optimove. All rights reserved.

import UIKit
import WebKit
import StoreKit
import UserNotifications

internal enum InAppAction: String {
    case CLOSE_MESSAGE = "closeMessage"
    case TRACK_EVENT = "trackConversionEvent"
    case PROMPT_PUSH_PERMISSION = "promptPushPermission"
    case OPEN_URL = "openUrl"
    case DEEP_LINK = "deepLink"
    case REQUEST_RATING = "requestAppStoreRating"
}

class InAppPresenter: NSObject, WKScriptMessageHandler, WKNavigationDelegate {

    private let messageQueueLock = DispatchSemaphore(value: 1)

    private var webView: WKWebView?
    private var loadingSpinner: UIActivityIndicatorView?
    private var frame: UIView?
    private var window: UIWindow?
    private var webViewReady = false

    private var contentController: WKUserContentController?

    private var messageQueue: NSMutableOrderedSet
    private var pendingTickleIds: NSMutableOrderedSet

    private var displayMode: InAppDisplayMode
    private var currentMessage: InAppMessage?

    init(displayMode: InAppDisplayMode) {
        self.messageQueue = NSMutableOrderedSet(capacity: 5)
        self.pendingTickleIds = NSMutableOrderedSet(capacity: 2)
        self.currentMessage = nil

        self.displayMode = displayMode

        super.init()
    }

    func setDisplayMode(_ mode: InAppDisplayMode) {
        runOnMainThreadSync {
            let resumed = mode != displayMode && mode != .paused

            displayMode = mode

            if resumed {
                presentFromQueue()
            }
        }
    }

    func getDisplayMode() -> InAppDisplayMode {
        var mode: InAppDisplayMode = .automatic

        runOnMainThreadSync {
            mode = displayMode
        }

        return mode
    }

    func queueMessagesForPresentation(messages: [InAppMessage], tickleIds: NSOrderedSet) {
        messageQueueLock.wait()

        if messages.count == 0 && messageQueue.count == 0 {
            messageQueueLock.signal()
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

            messageQueue.sort { (a, b) -> ComparisonResult in
                guard let a = a as? InAppMessage, let b = b as? InAppMessage else {
                    return .orderedSame
                }

                let aIsTickle = self.pendingTickleIds.contains(a.id)
                let bIsTickle = self.pendingTickleIds.contains(b.id)

                if aIsTickle && !bIsTickle {
                    return .orderedAscending
                } else if !aIsTickle && bIsTickle {
                    return .orderedDescending
                } else if aIsTickle && bIsTickle {
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

        let notShowingCurrentTickle = self.currentMessage != nil
            && self.currentMessage!.id != (self.messageQueue[0] as! InAppMessage).id
            && (self.messageQueue[0] as! InAppMessage).id == self.pendingTickleIds[0] as! Int64

        let queueNotEmptyAndNotShowingAnything = self.currentMessage == nil && self.messageQueue.count > 0

        let shouldShowSomething = notShowingCurrentTickle || queueNotEmptyAndNotShowingAnything

        messageQueueLock.signal()

        if shouldShowSomething {
            DispatchQueue.main.async {
                self.presentFromQueue()
            }
        }
    }

    func presentFromQueue() {
        messageQueueLock.wait()
        defer {
            messageQueueLock.signal()
        }

        if self.messageQueue.count == 0 || displayMode == .paused {
            DispatchQueue.main.async {
                self.destroyViews()
            }

            return
        }

        self.currentMessage = (self.messageQueue[0] as! InAppMessage)

        var ready = false

        runOnMainThreadSync {
            initViews()
            self.loadingSpinner?.startAnimating()
            ready = self.webViewReady
        }

        guard ready else {
            return
        }

        let content = NSMutableDictionary(dictionary: self.currentMessage!.content)
        content["region"] = Optimobile.sharedInstance.config.region

        self.postClientMessage(type: "PRESENT_MESSAGE", data: content)
    }

    func handleMessageClosed() {
        guard let message = currentMessage else {
            return
        }

        if #available(iOS 10, *) {
            let tickleNotificationId = "k-in-app-message:\(message.id)"
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [tickleNotificationId])

            PendingNotificationHelper.remove(identifier: tickleNotificationId)
        }

        messageQueueLock.wait()

        messageQueue.removeObject(at: 0)
        pendingTickleIds.remove(message.id)
        currentMessage = nil

        if messageQueue.count == 0 {
            pendingTickleIds.removeAllObjects()
        }

        messageQueueLock.signal()

        presentFromQueue()
   }

    func cancelCurrentPresentationQueue(waitForViewCleanup: Bool) {
        messageQueueLock.wait()

        self.messageQueue.removeAllObjects()
        self.pendingTickleIds.removeAllObjects()
        self.currentMessage = nil

        messageQueueLock.signal()

        if waitForViewCleanup == true {
            runOnMainThreadSync {
                self.destroyViews()
            }
        } else {
            DispatchQueue.main.async {
                self.destroyViews()
            }
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

        frame.backgroundColor = .clear

        window!.isHidden = false
        window!.rootViewController!.view = frame

        // Webview
        self.contentController = WKUserContentController()
        self.contentController!.add(self, name: "inAppHost")

        let config = WKWebViewConfiguration()
        config.userContentController = self.contentController!
        config.allowsInlineMediaPlayback = true

        if #available(iOS 10.0, *) {
            config.mediaTypesRequiringUserActionForPlayback = []
        } else {
            if #available(iOS 9.0, *) {
                config.requiresUserActionForMediaPlayback = false
            } else {
                config.mediaPlaybackRequiresUserAction = false
            }
        }

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
        let url = Optimobile.getInstance().urlBuilder.urlForService(.iar)
        let request = URLRequest(url: URL(string: url)!, cachePolicy: cachePolicy, timeoutInterval: 8)
        webView.load(request)

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
        if let window = self.window {
            window.isHidden = true

            if let spinner = self.loadingSpinner {
                spinner.removeFromSuperview()
                self.loadingSpinner = nil
            }

            if let webView = self.webView {
                webView.removeFromSuperview()
                self.webView = nil
            }

            if let frame = self.frame {
                frame.removeFromSuperview()
                self.frame = nil
            }
        }

        self.window = nil
        self.webViewReady = false
    }

    func postClientMessage(type: String, data: Any?) {
        guard let webView = self.webView else {
            return
        }

        do {

            let msg: [String: Any] = ["type": type, "data": data != nil ? data! : NSNull()]
            let json: Data = try JSONSerialization.data(withJSONObject: msg, options: JSONSerialization.WritingOptions(rawValue: 0))

            let jsonMsg = String(data: json, encoding: .utf8)
            let evalString = String(format: "postHostMessage(%@);", jsonMsg!)

            webView.evaluateJavaScript(evalString, completionHandler: nil)
        } catch {
            // Noop?
        }
      }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
       if message.name != "inAppHost" {
           return
       }

        let body = message.body as! NSDictionary
        let type = body["type"] as! String

        if type == "READY" {
            runOnMainThreadSync {
                self.webViewReady = true
            }

            self.presentFromQueue()
        } else if type == "MESSAGE_OPENED" {
            loadingSpinner?.stopAnimating()
            Optimobile.sharedInstance.inAppManager.handleMessageOpened(message: self.currentMessage!)
        } else if type == "MESSAGE_CLOSED" {
            self.handleMessageClosed()
        } else if type == "EXECUTE_ACTIONS" {
            guard let body = message.body as? [AnyHashable: Any],
                  let data = body["data"] as? [AnyHashable: Any],
                  let actions = data["actions"] as? [NSDictionary] else {
                return
            }
            self.handleActions(actions: actions)
        } else {
           print("Unknown message: \(message.body)")
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Noop
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // Handles transfer errors after starting load
        self.cancelCurrentPresentationQueue(waitForViewCleanup: false)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // Handles connection/timeout errors for the main frame load
        self.cancelCurrentPresentationQueue(waitForViewCleanup: false)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        // Handles HTTP responses for all status codes
        if let httpResponse = navigationResponse.response as? HTTPURLResponse,
           let url = httpResponse.url {
            let baseUrl = Optimobile.getInstance().urlBuilder.urlForService(.iar)
            if url.absoluteString.starts(with: baseUrl) && httpResponse.statusCode >= 400 {
                decisionHandler(.cancel)
                cancelCurrentPresentationQueue(waitForViewCleanup: false)
                return
            }
        }

        decisionHandler(.allow)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        self.cancelCurrentPresentationQueue(waitForViewCleanup: false)
    }

    func handleActions(actions: [NSDictionary]) {
        if let message = self.currentMessage {

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
                self.postClientMessage(type: "CLOSE_MESSAGE", data: nil)
            }

            if let conversionEvent = conversionEvent {
                Optimobile.trackEventImmediately(eventType: conversionEvent, properties: conversionEventData)
            }

            if userAction != nil {
                self.handleUserAction(message: message, userAction: userAction!)
                self.cancelCurrentPresentationQueue(waitForViewCleanup: true)
            }
        }
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
                UIApplication.shared.open(url, options: [:]) { (win) in
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

    private func runOnMainThreadSync(_ work: () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.sync(execute: work)
        }
    }

}
