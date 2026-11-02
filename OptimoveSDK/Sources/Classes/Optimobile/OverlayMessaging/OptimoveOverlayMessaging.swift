//  Copyright © 2025 Optimove. All rights reserved.

import Foundation

public class OptimoveOverlayMessaging {
    
    private static var shared: OptimoveOverlayMessaging?
    
    private let manager: OverlayMessagingManager
    private var sessionManager: OverlayMessagingSessionManager?
    private let sessionLengthMinutes: Int
    private var initializationToken: NSObjectProtocol?

    private init(sessionLengthMinutes: Int, httpClient: KSHttpClient, urlBuilder: UrlBuilder) {
        self.sessionLengthMinutes = sessionLengthMinutes
        self.manager = OverlayMessagingManager(httpClient: httpClient, urlBuilder: urlBuilder)
    }
    
    // MARK: - Public API
    
    public static func setInterceptor(_ interceptor: OverlayMessagingInterceptor?) {
        shared?.manager.setInterceptor(interceptor)
    }

    public static func setActionHandler(_ handler: OverlayActionHandler?) {
        shared?.manager.setActionHandler(handler)
    }

    /// Register an observer for overlays entering and leaving the screen. Pass `nil` to remove it.
    /// This is separate from `setActionHandler`: the listener observes only and cannot block or
    /// override a close. See `OverlayLifecycleListener` for the delivery guarantees.
    public static func setLifecycleListener(_ listener: OverlayLifecycleListener?) {
        ensureMain { shared?.manager.setLifecycleListener(listener) }
    }

    public static func resetSession() {
        shared?.sessionManager?.resetSession()
    }

    public static func hide() {
        ensureMain { shared?.manager.setHidden(true) }
    }

    public static func show() {
        ensureMain { shared?.manager.setHidden(false) }
    }
    
    // MARK: - Internal
    
    static func onPushTriggerReceived() {
        shared?.manager.onTriggerReceived(.immediate)
    }
    
    static func initialize(config: OptimobileConfig, httpClient: KSHttpClient, urlBuilder: UrlBuilder) {
        shared = OptimoveOverlayMessaging(sessionLengthMinutes: config.overlayMessagingSessionLengthMinutes, httpClient: httpClient, urlBuilder: urlBuilder)
        
        shared?.initializationToken = NotificationCenter.default
            .addObserver(forName: .optimobileInializationFinished, object: nil, queue: nil) { _ in
                DispatchQueue.main.async {
                    shared?.initializationToken = nil
                    shared?.startSessionManager()
                }
            }
    }
    
    // MARK: - Private
    
    private static func ensureMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    private func startSessionManager() {
        sessionManager = OverlayMessagingSessionManager(
            sessionLengthMinutes: sessionLengthMinutes,
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

// MARK: - Lifecycle listener

/// Why an overlay left the screen. This is an open set: new reasons may be added in future SDK
/// versions, so treat any value you don't recognise as "closed".
public struct OverlayCloseReason: RawRepresentable, Hashable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// A link action was dispatched while the message was on screen (sticky for that message).
    public static let actioned = OverlayCloseReason(rawValue: "actioned")
    /// The user closed the message without a link action (close button, close-only CTA).
    public static let dismissed = OverlayCloseReason(rawValue: "dismissed")
    /// Presentation failed. The message will not come back.
    public static let error = OverlayCloseReason(rawValue: "error")
}

/// Details of an overlay close. New fields may be added in future SDK versions.
public struct OverlayClosedInfo {
    public let reason: OverlayCloseReason
}

/// Observes overlays entering and leaving the screen. Register it with
/// `OptimoveOverlayMessaging.setLifecycleListener`. Both methods have default no-op
/// implementations, so implement only the ones you need.
///
/// Guarantees:
/// - `onShown` fires once when the SDK presents a message. It does not fire for messages the
///   interceptor defers or discards, or while overlays are hidden. A message held during `hide()`
///   fires when it is presented after `show()`.
/// - `onClosed` fires exactly once for every message `onShown` fired for, including when
///   presentation fails (`reason == .error`).
/// - `hide()` is not a close. A hidden overlay is still pending.
/// - A message's `onClosed` fires before the next message's `onShown`.
/// - Both run synchronously on the main thread, after the SDK has updated its own queue. A thrown
///   error is caught and logged and never disturbs the overlay queue.
/// - Nothing fires when the app is killed. The listener describes in-session lifecycle only.
public protocol OverlayLifecycleListener {
    func onShown(message: OverlayMessagingMessage) throws
    func onClosed(message: OverlayMessagingMessage, info: OverlayClosedInfo) throws
}

public extension OverlayLifecycleListener {
    func onShown(message: OverlayMessagingMessage) {}
    func onClosed(message: OverlayMessagingMessage, info: OverlayClosedInfo) {}
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

