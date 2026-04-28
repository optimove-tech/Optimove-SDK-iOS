//  Copyright © 2025 Optimove. All rights reserved.

import Foundation
import UIKit

class OverlayMessagingSessionManager {
    
    typealias SessionStartedListener = () -> Void
    
    private static let prefsKey = "optimove_om_last_session_start"
    private static let scheduleBufferSeconds: TimeInterval = 1.0
    
    private let sessionLength: TimeInterval
    private let listener: SessionStartedListener
    private var timer: Timer?
    private var appInForeground = false
    
    init(sessionLengthHours: Int, listener: @escaping SessionStartedListener) {
        self.sessionLength = TimeInterval(sessionLengthHours) * 3600.0
        self.listener = listener
        registerListeners()
    }
    
    // MARK: - Internal
    
    func resetSession() {
        UserDefaults.standard.removeObject(forKey: Self.prefsKey)
        guard appInForeground else { return }
        cancelTimer()
        startNewSession()
        scheduleNextTick()
    }
    
    // MARK: - Lifecycle
    
    @objc private func appEnteredForeground() {
        appInForeground = true
        
        let lastSessionStart = UserDefaults.standard.double(forKey: Self.prefsKey)
        let noPreviousSession = lastSessionStart == 0
        let sessionExpired = (Date().timeIntervalSince1970 - lastSessionStart) >= sessionLength
        
        if noPreviousSession || sessionExpired {
            startNewSession()
        }
        scheduleNextTick()
    }
    
    @objc private func appEnteredBackground() {
        appInForeground = false
        cancelTimer()
    }
    
    // MARK: - Timer
    
    private func scheduleNextTick() {
        cancelTimer()
        let lastSessionStart = UserDefaults.standard.double(forKey: Self.prefsKey)
        let nextSessionAt = lastSessionStart + sessionLength + Self.scheduleBufferSeconds
        let delay = max(0, nextSessionAt - Date().timeIntervalSince1970)
        
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.startNewSession()
            self?.scheduleNextTick()
        }
    }
    
    private func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Session
    
    private func startNewSession() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Self.prefsKey)
        listener()
    }
    
    // MARK: - Registration
    
    private func registerListeners() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appEnteredForeground),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appEnteredBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
}
