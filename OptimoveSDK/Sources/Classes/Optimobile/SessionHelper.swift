//  Copyright © 2022 Optimove. All rights reserved.

import Foundation
import UIKit

class SessionIdleTimer {
    private let helper: SessionHelper
    private var invalidationLock: DispatchSemaphore
    private var invalidated: Bool

    init(_ helper: SessionHelper, timeout: UInt) {
        invalidationLock = DispatchSemaphore(value: 1)
        invalidated = false
        self.helper = helper

        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .seconds(Int(timeout))) {
            self.invalidationLock.wait()

            if self.invalidated {
                self.invalidationLock.signal()
                return
            }

            self.invalidationLock.signal()
            helper.sessionDidEnd()
        }
    }

    func invalidate() {
        invalidationLock.wait()
        invalidated = true
        invalidationLock.signal()
    }
}

class SessionHelper {
    private var startNewSession: Bool
    private var becameInactiveAt: Date?
    private var sessionIdleTimer: SessionIdleTimer?
    private var bgTask: UIBackgroundTaskIdentifier
    private var sessionIdleTimeout: UInt

    init(sessionIdleTimeout: UInt) {
        startNewSession = true
        sessionIdleTimer = nil
        bgTask = UIBackgroundTaskIdentifier.invalid
        becameInactiveAt = nil
        self.sessionIdleTimeout = sessionIdleTimeout
    }

    func initialize() {
        registerListeners()
    }

    private func registerListeners() {
        NotificationCenter.default.addObserver(self, selector: #selector(appBecameActive), name: UIApplication.didBecomeActiveNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(appBecameInactive), name: UIApplication.willResignActiveNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(appBecameBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
    }

    // MARK: App lifecycle delegates

    @objc private func appBecameActive() {
        if startNewSession {
            Optimobile.trackEvent(eventType: OptimobileEvent.STATS_FOREGROUND, properties: nil)
            startNewSession = false
            return
        }

        if sessionIdleTimer != nil {
            sessionIdleTimer?.invalidate()
            sessionIdleTimer = nil
        }

        if bgTask != UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask(bgTask)
            bgTask = UIBackgroundTaskIdentifier.invalid
        }
    }

    @objc private func appBecameInactive() {
        becameInactiveAt = Date()

        sessionIdleTimer = SessionIdleTimer(self, timeout: sessionIdleTimeout)
    }

    @objc private func appBecameBackground() {
        bgTask = UIApplication.shared.beginBackgroundTask(withName: "ksession", expirationHandler: {
            UIApplication.shared.endBackgroundTask(self.bgTask)
            self.bgTask = UIBackgroundTaskIdentifier.invalid
        })

        if becameInactiveAt == nil {
            becameInactiveAt = Date()
        }
    }

    @objc private func appWillTerminate() {
        if becameInactiveAt == nil {
            becameInactiveAt = Date()
        }

        if sessionIdleTimer != nil {
            sessionIdleTimer?.invalidate()
            sessionDidEnd()
        }
    }

    fileprivate func sessionDidEnd() {
        guard let sessionEndTime = becameInactiveAt else {
            return
        }

        startNewSession = true
        sessionIdleTimer = nil

        // Track the background event asynchronously to avoid blocking the calling thread
        Optimobile.trackEvent(eventType: OptimobileEvent.STATS_BACKGROUND.rawValue, atTime: sessionEndTime, properties: nil, immediateFlush: true, onSyncComplete: { _ in
            // Clean up on completion without blocking the main flow
            DispatchQueue.main.async {
                self.becameInactiveAt = nil

                if self.bgTask != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(self.bgTask)
                    self.bgTask = UIBackgroundTaskIdentifier.invalid
                }
            }
        })
    }
}
