//  Copyright © 2025 Optimove. All rights reserved.

import Foundation

public class OptimoveOverlayMessaging {

    private static var shared: OptimoveOverlayMessaging?

    private var sessionManager: OverlayMessagingSessionManager?
    private let sessionLengthHours: Int
    private var initializationToken: NSObjectProtocol?

    private init(sessionLengthHours: Int) {
        self.sessionLengthHours = sessionLengthHours
    }

    // MARK: - Public API

    public static func resetSession() {
        shared?.sessionManager?.resetSession()
    }

    // MARK: - Internal

    static func initialize(config: OptimobileConfig) {
        shared = OptimoveOverlayMessaging(sessionLengthHours: config.overlayMessagingSessionLengthHours)

        shared?.initializationToken = NotificationCenter.default
            .addObserver(forName: .optimobileInializationFinished, object: nil, queue: nil) { _ in
                DispatchQueue.main.async {
                    shared?.initializationToken = nil
                    shared?.startSessionManager()
                }
            }
    }

    private func startSessionManager() {
        sessionManager = OverlayMessagingSessionManager(
            sessionLengthHours: sessionLengthHours,
            listener: { [weak self] in
                self?.onSessionStarted()
            }
        )
    }

    private func onSessionStarted() {
        // Will forward to OverlayMessagingManager.onTriggerReceived(.session)
    }
}
