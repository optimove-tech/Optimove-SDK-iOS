//  Copyright © 2022 Optimove. All rights reserved.

import Foundation
import OptimoveCore
import UIKit

public struct DeepLinkContent {
    let title: String?
    let description: String?
}

public struct DeepLink {
    public let url: URL
    public let content: DeepLinkContent
    public let data: [AnyHashable: Any?]

    init?(for url: URL, from jsonData: Data) {
        guard let response = try? JSONSerialization.jsonObject(with: jsonData) as? [AnyHashable: Any],
              let linkData = response["linkData"] as? [AnyHashable: Any?],
              let content = response["content"] as? [AnyHashable: Any?]
        else {
            return nil
        }

        self.url = url
        self.content = DeepLinkContent(title: content["title"] as? String, description: content["description"] as? String)
        data = linkData
    }
}

public enum DeepLinkResolution {
    case lookupFailed(_ url: URL)
    case linkNotFound(_ url: URL)
    case linkExpired(_ url: URL)
    case linkLimitExceeded(_ url: URL)
    case linkMatched(_ data: DeepLink)
}

public typealias DeepLinkHandler = (DeepLinkResolution) -> Void

final class DeepLinkHelper {
    struct CachedLink {
        let url: URL
        let wasDeferred: Bool
    }

    let config: OptimobileConfig
    let httpClient: KSHttpClient
    let storage: OptimoveStorage
    var anyContinuationHandled: Bool
    var cachedLink: CachedLink?
    var finishedInitializationToken: NSObjectProtocol?

    init(_ config: OptimobileConfig, httpClient: KSHttpClient, storage: OptimoveStorage) {
        self.config = config
        self.httpClient = httpClient
        self.storage = storage
        anyContinuationHandled = false

        finishedInitializationToken = NotificationCenter.default
            .addObserver(forName: .optimobileInializationFinished, object: nil, queue: nil) { [weak self] notification in
                self?.maybeProcessCache()
                Logger.debug("Notification \(notification.name.rawValue) was processed")
            }
    }

    func maybeProcessCache() {
        if let cachedLink = cachedLink {
            handleDeepLinkUrl(cachedLink.url, wasDeferred: cachedLink.wasDeferred)
            self.cachedLink = nil
        }
    }

    func checkForNonContinuationLinkMatch() {
        if checkForDeferredLinkOnClipboard() {
            return
        }

        NotificationCenter.default.addObserver(self, selector: #selector(appBecameActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc func appBecameActive() {
        NotificationCenter.default.removeObserver(self)
    }

    private func checkForDeferredLinkOnClipboard() -> Bool {
        var handled = false

        if let checked: Bool? = storage[.deferredLinkChecked], checked == true {
            return handled
        }

        var shouldCheck = false
        if #available(iOS 10.0, *) {
            shouldCheck = UIPasteboard.general.hasURLs
        } else {
            shouldCheck = true
        }

        if shouldCheck, let url = UIPasteboard.general.url, urlShouldBeHandled(url) {
            UIPasteboard.general.urls = UIPasteboard.general.urls?.filter { $0 != url }
            handleDeepLinkUrl(url, wasDeferred: true)
            handled = true
        }

        storage.set(value: true, key: .deferredLinkChecked)

        return handled
    }
    
    private func urlShouldBeHandled(_ url: URL) -> Bool {
        guard let host = url.host else {
            return false
        }

        return host.hasSuffix("lnk.click") || host == config.deepLinkCname?.host
    }

    private func handleDeepLinkUrl(_ url: URL, wasDeferred: Bool = false) {
        let slug = KSHttpUtil.urlEncode(url.path.trimmingCharacters(in: ["/"]))

        var path = "/v1/deeplinks/\(slug ?? "")?wasDeferred=\(wasDeferred ? 1 : 0)"
        if let query = url.query {
            path = path + "&" + query
        }

        httpClient.sendRequest(.GET, toPath: path, data: nil, onSuccess: { res, data in
            switch res?.statusCode {
            case 200:
                guard let jsonData = data as? Data,
                      let link = DeepLink(for: url, from: jsonData)
                else {
                    self.invokeDeepLinkHandler(.lookupFailed(url))
                    return
                }

                self.invokeDeepLinkHandler(.linkMatched(link))

                let linkProps = ["url": url.absoluteString, "wasDeferred": wasDeferred] as [String: Any]
                Optimobile.getInstance().analyticsHelper.trackEvent(eventType: OptimobileEvent.DEEP_LINK_MATCHED.rawValue, properties: linkProps, immediateFlush: false)
            default:
                self.invokeDeepLinkHandler(.lookupFailed(url))
            }
        }, onFailure: { res, error, _ in
            if let error = error {
                if case HttpAuthorizationError.missingAuthHeader = error {
                    self.cachedLink = CachedLink(url: url, wasDeferred: wasDeferred)
                    return
                }
            }
            switch res?.statusCode {
            case 404:
                self.invokeDeepLinkHandler(.linkNotFound(url))
            case 410:
                self.invokeDeepLinkHandler(.linkExpired(url))
            case 429:
                self.invokeDeepLinkHandler(.linkLimitExceeded(url))
            default:
                self.invokeDeepLinkHandler(.lookupFailed(url))
            }
        })
    }

    private func invokeDeepLinkHandler(_ resolution: DeepLinkResolution) {
        DispatchQueue.main.async {
            self.config.deepLinkHandler?(resolution)
        }
    }

    @discardableResult
    fileprivate func handleContinuation(for userActivity: NSUserActivity) -> Bool {
        if config.deepLinkHandler == nil {
            print("Optimobile deep link handler not configured, aborting...")
            return false
        }

        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL,
              urlShouldBeHandled(url)
        else {
            return false
        }

        handleDeepLinkUrl(url)
        return true
    }
}

extension Optimobile {
    static func application(_: UIApplication, continue userActivity: NSUserActivity, restorationHandler _: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return getInstance().deepLinkHelper?.handleContinuation(for: userActivity) ?? false
    }

    @available(iOS 13.0, *)
    static func scene(_: UIScene, continue userActivity: NSUserActivity) {
        getInstance().deepLinkHelper?.handleContinuation(for: userActivity)
    }
}
