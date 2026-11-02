//  Copyright © 2025 Optimove. All rights reserved.

import Foundation

/// Tracks the overlay that is currently on screen and turns presentation, link action and close
/// signals into `OverlayLifecycleListener` callbacks with the exactly-once guarantees of the
/// lifecycle contract. Must be driven from the main thread.
final class OverlayLifecycleNotifier {

    private var listener: OverlayLifecycleListener?
    private let logError: (String) -> Void

    /// The message `onShown` fired for and whose `onClosed` has not fired yet.
    private var shownMessageId: Int64?
    /// Sticky per shown message: a link action was dispatched while it was up.
    private var actioned = false

    init(logError: @escaping (String) -> Void = { Logger.error($0) }) {
        self.logError = logError
    }

    func setListener(_ listener: OverlayLifecycleListener?) {
        self.listener = listener
    }

    /// The SDK has handed `message` to the presenter. Repeated calls for the same message
    /// (for example `show()` after `hide()`) are ignored.
    func messagePresented(_ message: OverlayMessagingMessage) {
        guard shownMessageId != message.id else { return }
        shownMessageId = message.id
        actioned = false
        notify("onShown") { try $0.onShown(message: message) }
    }

    /// A link action has been dispatched for `message`.
    func linkActionDispatched(_ message: OverlayMessagingMessage) {
        guard shownMessageId == message.id else { return }
        actioned = true
    }

    /// `message` has left the screen, either closed by the user or failed (`failed: true`).
    /// Fires at most once per shown message; closes for messages that were never shown are ignored.
    func messageClosed(_ message: OverlayMessagingMessage, failed: Bool) {
        guard shownMessageId == message.id else { return }
        let reason: OverlayCloseReason = failed ? .error : (actioned ? .actioned : .dismissed)
        shownMessageId = nil
        actioned = false
        notify("onClosed") { try $0.onClosed(message: message, info: OverlayClosedInfo(reason: reason)) }
    }

    private func notify(_ name: String, _ call: (OverlayLifecycleListener) throws -> Void) {
        guard let listener = listener else { return }
        do {
            try call(listener)
        } catch {
            logError("Overlay lifecycle listener \(name) threw: \(error.localizedDescription)")
        }
    }
}
