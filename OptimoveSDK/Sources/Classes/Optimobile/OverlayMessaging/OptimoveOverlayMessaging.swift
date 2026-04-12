//  Copyright © 2025 Optimove. All rights reserved.

import Foundation

public class OptimoveOverlayMessaging {

    private static var shared: OptimoveOverlayMessaging?

    private let manager: OverlayMessagingManager
    private var sessionManager: OverlayMessagingSessionManager?
    private let sessionLengthHours: Int
    private var initializationToken: NSObjectProtocol?

    private init(sessionLengthHours: Int, httpClient: KSHttpClient) {
        self.sessionLengthHours = sessionLengthHours
        self.manager = OverlayMessagingManager(httpClient: httpClient)
    }

    // MARK: - Public API

    public static func resetSession() {
        shared?.sessionManager?.resetSession()
    }

    // MARK: - Internal

    static func onPushTriggerReceived() {
        shared?.manager.onTriggerReceived(.immediate)
    }

    static func initialize(config: OptimobileConfig, httpClient: KSHttpClient) {
        shared = OptimoveOverlayMessaging(sessionLengthHours: config.overlayMessagingSessionLengthHours, httpClient: httpClient)

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
