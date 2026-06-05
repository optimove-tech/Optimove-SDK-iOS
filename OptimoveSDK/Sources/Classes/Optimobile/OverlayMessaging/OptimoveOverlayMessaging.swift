//  Copyright © 2025 Optimove. All rights reserved.

import Foundation

public class OptimoveOverlayMessaging {
    
    private static var shared: OptimoveOverlayMessaging?
    
    private let manager: OverlayMessagingManager
    private var sessionManager: OverlayMessagingSessionManager?
    private let sessionLengthHours: Int
    private var initializationToken: NSObjectProtocol?
    
    private init(sessionLengthHours: Int, httpClient: KSHttpClient, urlBuilder: UrlBuilder) {
        self.sessionLengthHours = sessionLengthHours
        self.manager = OverlayMessagingManager(httpClient: httpClient, urlBuilder: urlBuilder)
    }
    
    // MARK: - Public API
    
    public static func setInterceptor(_ interceptor: OverlayMessagingInterceptor?) {
        shared?.manager.setInterceptor(interceptor)
    }

    public static func setActionHandler(_ handler: OverlayActionHandler?) {
        shared?.manager.setActionHandler(handler)
    }

    public static func resetSession() {
        shared?.sessionManager?.resetSession()
    }
    
    // MARK: - Internal
    
    static func onPushTriggerReceived() {
        shared?.manager.onTriggerReceived(.immediate)
    }
    
    static func initialize(config: OptimobileConfig, httpClient: KSHttpClient, urlBuilder: UrlBuilder) {
        shared = OptimoveOverlayMessaging(sessionLengthHours: config.overlayMessagingSessionLengthHours, httpClient: httpClient, urlBuilder: urlBuilder)
        
        shared?.initializationToken = NotificationCenter.default
            .addObserver(forName: .optimobileInializationFinished, object: nil, queue: nil) { _ in
                DispatchQueue.main.async {
                    shared?.initializationToken = nil
                    shared?.startSessionManager()
                }
            }
    }
    
    // MARK: - Private
    
    private func startSessionManager() {
        sessionManager = OverlayMessagingSessionManager(
            sessionLengthHours: sessionLengthHours,
            listener: { [weak self] in
                self?.manager.onTriggerReceived(.session)
            }
        )
    }
}

// MARK: - Action handler

/// Typed payload for a link CTA. New fields may be added in future SDK versions.
public struct LinkActionPayload {
    public let url: String
}

/// One method per overlay action type, each with its own typed payload. Conform to this protocol
/// and pass an instance to `setActionHandler` to take over one or more actions. Every method has
/// a default implementation in a protocol extension — only override the actions you want to own.
/// New action types will be added as new methods with defaults, so existing conformers are never
/// broken by SDK updates.
public protocol OverlayActionHandler {
    func linkAction(message: OverlayMessagingMessage, payload: LinkActionPayload) throws
}

// MARK: - Interceptor protocols

public protocol OverlayMessagingInterceptorCallback: AnyObject {
    func show()
    func discard()
    func deferMessage()
}

public protocol OverlayMessagingInterceptor: AnyObject {
    func onMessageLoaded(_ message: OverlayMessagingMessage, callback: OverlayMessagingInterceptorCallback)
    func getTimeoutMs() -> Int
}

public extension OverlayMessagingInterceptor {
    func getTimeoutMs() -> Int { 5000 }
}

