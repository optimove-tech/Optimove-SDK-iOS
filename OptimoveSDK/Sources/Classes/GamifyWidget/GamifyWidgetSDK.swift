//  Copyright © 2026 Optimove. All rights reserved.

import OptimoveCore
import UIKit

/// Entry point for the Gamify Widget SDK (loyalty + Adact).
///
/// Usage (loyalty — opens `{loyaltyWidgetUrl}/{tenantId}/{userId}` for the identified SDK user; when auth is enabled
/// via `OptimoveConfigBuilder.enableAuth`, a JWT is minted for that user and passed in INIT):
///   GamifyWidgetSDK.openWidget(from: viewController)
///   GamifyWidgetSDK.openWidget(from: viewController, params: OpenLoyaltyWidgetParams(userId: "u123", brand: "brand"))
///
/// Usage (Adact):
///   GamifyWidgetSDK.openAdactCampaign(from: viewController, params: OpenAdactParams(campaignId: 179, cid: "cid", token: "token"))
public final class GamifyWidgetSDK {

    struct Environment {
        var currentUserId: () -> String?
        var authManager: () -> AuthManager?

        static let live = Environment(
            currentUserId: { Optimove.currentCustomerId() },
            authManager: { Optimove.currentAuthManager() }
        )
    }

    struct TenantOptions: Equatable {
        var adactUrl: String?
        var loyaltyWidgetUrl: String?
        var tenantId: Int

        static let empty = TenantOptions(adactUrl: nil, loyaltyWidgetUrl: nil, tenantId: -1)
    }

    private static let lock = NSLock()
    private static var _tenantOptions = TenantOptions.empty

    internal static var tenantOptions: TenantOptions {
        lock.lock()
        defer { lock.unlock() }
        return _tenantOptions
    }

    internal static var environment = Environment.live

    private weak static var loyaltyViewController: GamifyWidgetViewController?
    private weak static var adactViewController: GamifyWidgetViewController?

    private init() {}

    /// Applies the `gamify` block of the tenant configuration. Called by the SDK when the configuration is fetched;
    /// not intended for host apps.
    internal static func applyTenantConfiguration(adactUrl: String?, loyaltyWidgetUrl: String?, tenantId: Int) {
        let options = TenantOptions(
            adactUrl: normalizeBaseUrl(adactUrl),
            loyaltyWidgetUrl: normalizeBaseUrl(loyaltyWidgetUrl),
            tenantId: tenantId
        )
        lock.lock()
        _tenantOptions = options
        lock.unlock()
        Logger.debug("GamifyWidgetSDK applied tenant configuration: adactUrl=\(adactUrl ?? "nil"), loyaltyWidgetUrl=\(loyaltyWidgetUrl ?? "nil"), tenantId=\(tenantId)")
    }

    /// Returns the configured Adact host with a trailing slash, or empty when unset.
    public static func getAdactUrl() -> String {
        guard let adactUrl = tenantOptions.adactUrl else { return "" }
        return adactUrl + "/"
    }

    /// Present the loyalty widget in a modal sheet.
    ///
    /// Opens `{loyaltyWidgetUrl}/{tenantId}[/brand/{brand}]/{userId}`, where `userId` defaults to the identified SDK
    /// user. When auth is enabled, a JWT for that user is fetched from the `AuthTokenProvider` and passed in the
    /// widget's INIT message; if the token can't be fetched the widget closes instead of opening unauthenticated.
    public static func openWidget(
        from viewController: UIViewController,
        params: OpenLoyaltyWidgetParams = OpenLoyaltyWidgetParams()
    ) {
        ensureMain { openWidget_onMain(from: viewController, params: params) }
    }

    private static func openWidget_onMain(
        from viewController: UIViewController,
        params: OpenLoyaltyWidgetParams
    ) {
        assertOnMainThread()
        let userId = params.userId ?? environment.currentUserId()
        let widgetSrc = buildLoyaltyWidgetUrl(userId: userId, brand: params.brand)
        guard !widgetSrc.isEmpty else {
            Logger.error("Cannot open the loyalty widget: \(describeMissingLoyaltyInputs(userId: userId))")
            return
        }
        if loyaltyViewController != nil {
            return
        }

        // Dismiss Adact first (if open), then present — avoids UIKit "presentation in progress" races.
        dismissOverlay(adactViewController, clearing: { adactViewController = nil }) {
            let vc = GamifyWidgetViewController(
                widgetUrl: widgetSrc,
                userId: userId,
                tokenSource: tokenSource(for: userId)
            )
            present(vc, from: viewController)
            loyaltyViewController = vc
        }
    }

    internal static func tokenSource(for userId: String?) -> GamifyWidgetViewController.TokenSource {
        guard let authManager = environment.authManager(), let userId = userId, !userId.isEmpty else {
            return { completion in completion(.success(nil)) }
        }
        return { completion in
            authManager.getToken(userId: userId) { result in
                completion(result.map { Optional($0) })
            }
        }
    }

    public static func buildLoyaltyWidgetUrl(userId: String?, brand: String?) -> String {
        let options = tenantOptions
        guard let loyaltyWidgetUrl = options.loyaltyWidgetUrl, options.tenantId > 0,
              let userId = userId, !userId.isEmpty else {
            return ""
        }

        let brandSegment = brand.flatMap { $0.isEmpty ? nil : "/brand/\(encodePathSegment($0))" } ?? ""
        let url = "\(loyaltyWidgetUrl)/\(options.tenantId)\(brandSegment)/\(encodePathSegment(userId))"
        guard URL(string: url)?.scheme?.lowercased() == "https" else { return "" }
        return url
    }

    private static func describeMissingLoyaltyInputs(userId: String?) -> String {
        let options = tenantOptions
        var missing: [String] = []
        if options.loyaltyWidgetUrl == nil {
            missing.append("loyaltyWidgetUrl (gamify.loyaltyWidgetUrl in the tenant configuration)")
        }
        if options.tenantId <= 0 {
            missing.append("tenantId (tenant configuration not loaded yet?)")
        }
        if userId?.isEmpty ?? true {
            missing.append("userId (pass one in OpenLoyaltyWidgetParams or call Optimove.setUserId)")
        }
        if missing.isEmpty {
            return "loyaltyWidgetUrl is not HTTPS: \(options.loyaltyWidgetUrl ?? "")"
        }
        return "missing " + missing.joined(separator: ", ")
    }

    private static func encodePathSegment(_ value: String) -> String {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
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
            Logger.error("GamifyWidgetSDK.openAdactCampaign called with invalid adactUrl (gamify.adactUrl in the tenant configuration) or campaignId.")
            return
        }
        if adactViewController != nil {
            return
        }

        dismissOverlay(loyaltyViewController, clearing: { loyaltyViewController = nil }) {
            let vc = GamifyWidgetViewController(widgetUrl: campaignUrl)
            present(vc, from: viewController)
            adactViewController = vc
        }
    }

    /// Builds `{adactUrl}/embedded/{campaignId}?cid=&customerIdToken=`.
    /// Returns empty string when `adactUrl` or `campaignId` is missing, or URL is not HTTPS.
    public static func buildAdactCampaignUrl(params: OpenAdactParams) -> String {
        guard let adactUrl = tenantOptions.adactUrl, let campaignId = params.campaignId else {
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
        dismissOverlay(loyaltyViewController, clearing: { loyaltyViewController = nil })
    }

    public static func closeAdactCampaign() {
        ensureMain { closeAdactCampaign_onMain() }
    }

    private static func closeAdactCampaign_onMain() {
        assertOnMainThread()
        dismissOverlay(adactViewController, clearing: { adactViewController = nil })
    }

    private static func dismissOverlay(
        _ overlay: GamifyWidgetViewController?,
        clearing: () -> Void,
        completion: (() -> Void)? = nil
    ) {
        guard let overlay = overlay else {
            completion?()
            return
        }
        clearing()
        overlay.dismiss(animated: true, completion: completion)
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

    internal static func resetForTesting(environment: Environment = .live) {
        lock.lock()
        _tenantOptions = .empty
        lock.unlock()
        self.environment = environment
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
