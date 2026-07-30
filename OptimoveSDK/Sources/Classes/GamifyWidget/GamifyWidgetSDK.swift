//  Copyright © 2026 Optimove. All rights reserved.

import UIKit

/// Entry point for the Gamify Widget SDK (loyalty + Adact).
///
/// Usage (loyalty):
///   GamifyWidgetSDK.initialize(widgetUrl: "https://your-widget.example.com")
///   GamifyWidgetSDK.open(from: viewController, userId: "u123")
///
/// Usage (Adact — `adactUrl` from onboarding / retrieval service):
///   GamifyWidgetSDK.initialize(widgetUrl: widgetUrl, adactUrl: "https://adact-campaign.example.com/")
///   GamifyWidgetSDK.openAdactCampaign(from: viewController, params: OpenAdactParams(campaignId: 179, cid: "cid", token: "token"))
public final class GamifyWidgetSDK {

    internal static var widgetUrl: String = ""
    internal static var adactUrl: String?

    private weak static var loyaltyViewController: GamifyWidgetViewController?
    private weak static var adactViewController: GamifyWidgetViewController?

    private init() {}

    /// Configure the loyalty widget URL (and optional Adact host) before opening.
    ///
    /// - Parameters:
    ///   - widgetUrl: Loyalty widget base URL (may be empty if only Adact is used).
    ///   - adactUrl: Adact campaign host from config (trailing slash optional);
    ///               region-correct URL is supplied by onboarding / retrieval service.
    public static func initialize(widgetUrl: String, adactUrl: String? = nil) {
        ensureMain { initialize_onMain(widgetUrl: widgetUrl, adactUrl: adactUrl) }
    }

    private static func initialize_onMain(widgetUrl: String, adactUrl: String?) {
        assertOnMainThread()
        self.widgetUrl = widgetUrl
        self.adactUrl = Self.normalizeBaseUrl(adactUrl)
    }

    /// Returns the configured Adact host with a trailing slash, or empty when unset.
    public static func getAdactUrl() -> String {
        guard let adactUrl = adactUrl, !adactUrl.isEmpty else { return "" }
        return adactUrl + "/"
    }

    /// Present the loyalty widget in a modal sheet.
    ///
    /// - Parameters:
    ///   - viewController: The presenting UIViewController.
    ///   - userId: Optional user ID injected via INIT handshake.
    ///   - token: Optional auth token injected via INIT handshake.
    public static func open(
        from viewController: UIViewController,
        userId: String? = nil,
        token: String? = nil
    ) {
        ensureMain { open_onMain(from: viewController, userId: userId, token: token) }
    }

    private static func open_onMain(
        from viewController: UIViewController,
        userId: String? = nil,
        token: String? = nil
    ) {
        assertOnMainThread()
        guard !widgetUrl.isEmpty, let url = URL(string: widgetUrl), url.scheme?.lowercased() == "https" else {
            Logger.error("GamifyWidgetSDK.open called with an invalid widgetUrl.")
            return
        }
        if loyaltyViewController != nil {
            return
        }
        // Both surfaces are modal overlays on iOS — only one at a time.
        closeAdactCampaign_onMain()

        let vc = GamifyWidgetViewController(
            widgetUrl: widgetUrl,
            userId: userId,
            token: token,
            enableInitHandshake: true
        )
        present(vc, from: viewController)
        loyaltyViewController = vc
    }

    /// Opens an Adact embedded campaign overlay.
    /// Does not perform the loyalty READY→INIT handshake; identity is passed via URL query params.
    public static func openAdactCampaign(
        from viewController: UIViewController,
        params: OpenAdactParams
    ) {
        ensureMain { openAdactCampaign_onMain(from: viewController, params: params) }
    }

    private static func openAdactCampaign_onMain(
        from viewController: UIViewController,
        params: OpenAdactParams
    ) {
        assertOnMainThread()
        let campaignUrl = buildAdactCampaignUrl(params: params)
        guard !campaignUrl.isEmpty else {
            Logger.error("GamifyWidgetSDK.openAdactCampaign called with invalid adactUrl or campaignId.")
            return
        }
        if adactViewController != nil {
            return
        }
        closeWidget_onMain()

        let vc = GamifyWidgetViewController(
            widgetUrl: campaignUrl,
            userId: nil,
            token: nil,
            enableInitHandshake: false
        )
        present(vc, from: viewController)
        adactViewController = vc
    }

    /// Builds `{adactUrl}/embedded/{campaignId}?cid=&customerIdToken=`.
    /// Returns empty string when `adactUrl` or `campaignId` is missing, or URL is not HTTPS.
    public static func buildAdactCampaignUrl(params: OpenAdactParams) -> String {
        guard let adactUrl = adactUrl, !adactUrl.isEmpty, let campaignId = params.campaignId else {
            return ""
        }

        var components = URLComponents(string: "\(adactUrl)/embedded/\(campaignId)")
        guard let scheme = components?.scheme?.lowercased(), scheme == "https" else {
            return ""
        }

        var items: [URLQueryItem] = []
        if let cid = params.cid, !cid.isEmpty {
            items.append(URLQueryItem(name: "cid", value: cid))
        }
        if let token = params.token, !token.isEmpty {
            items.append(URLQueryItem(name: "customerIdToken", value: token))
        }
        if !items.isEmpty {
            components?.queryItems = items
        }
        return components?.url?.absoluteString ?? ""
    }

    public static func closeWidget() {
        ensureMain { closeWidget_onMain() }
    }

    private static func closeWidget_onMain() {
        assertOnMainThread()
        loyaltyViewController?.dismiss(animated: true)
        loyaltyViewController = nil
    }

    public static func closeAdactCampaign() {
        ensureMain { closeAdactCampaign_onMain() }
    }

    private static func closeAdactCampaign_onMain() {
        assertOnMainThread()
        adactViewController?.dismiss(animated: true)
        adactViewController = nil
    }

    private static func present(_ vc: GamifyWidgetViewController, from presenter: UIViewController) {
        if #available(iOS 15.0, *) {
            if let sheet = vc.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
            }
        } else {
            vc.modalPresentationStyle = .pageSheet
        }
        presenter.present(vc, animated: true)
    }

    internal static func normalizeBaseUrl(_ url: String?) -> String? {
        guard let url = url, !url.isEmpty else { return nil }
        if url.hasSuffix("/") {
            return String(url.dropLast())
        }
        return url
    }

    private static func ensureMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    private static func assertOnMainThread(_ message: String = "Must be on main thread") {
        assert(Thread.isMainThread, message)
    }
}
