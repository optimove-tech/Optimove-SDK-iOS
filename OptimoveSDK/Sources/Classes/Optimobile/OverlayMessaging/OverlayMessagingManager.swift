//  Copyright © 2025 Optimove. All rights reserved.

import Foundation

class OverlayMessagingManager {

    private static let sessionSlotCapacity = 1
    private static let immediateSlotCapacity = 1

    private var sessionSlotCount = 0
    private var immediateSlotCount = 0

    private var displayQueue: [OverlayMessagingMessage] = []
    private let requestService: OverlayMessagingRequestService
    private var interceptor: OverlayMessagingInterceptor?

    init(httpClient: KSHttpClient) {
        requestService = OverlayMessagingRequestService(httpClient: httpClient)
    }

    // MARK: - Interceptor

    func setInterceptor(_ interceptor: OverlayMessagingInterceptor?) {
        self.interceptor = interceptor
    }

    // MARK: - Triggers

    func onTriggerReceived(_ type: OverlayMessagingMessage.MessageType) {
        switch type {
        case .session:
            guard sessionSlotCount < Self.sessionSlotCapacity else { return }
            sessionSlotCount += 1
            loadMessage(type)
        case .immediate:
            guard immediateSlotCount < Self.immediateSlotCapacity else { return }
            immediateSlotCount += 1
            loadMessage(type)
        }
    }

    // MARK: - Slots

    private func onSlotCleared(_ type: OverlayMessagingMessage.MessageType) {
        switch type {
        case .session:
            sessionSlotCount = max(0, sessionSlotCount - 1)
        case .immediate:
            immediateSlotCount = max(0, immediateSlotCount - 1)
        }
    }

    // MARK: - Loading

    private func loadMessage(_ type: OverlayMessagingMessage.MessageType) {
        requestService.readOverlayMessage(type: type) { message in
            DispatchQueue.main.async {
                self.onMessageLoaded(type: type, message: message)
            }
        }
    }

    private func onMessageLoaded(type: OverlayMessagingMessage.MessageType, message: OverlayMessagingMessage?) {
        guard let message = message else {
            onSlotCleared(type)
            return
        }
        processMessage(message)
    }

    // MARK: - Processing

    private func processMessage(_ message: OverlayMessagingMessage) {
        guard let interceptor = interceptor else {
            displayQueue.append(message)
            maybeShowNext()
            return
        }

        let callback = InterceptorCallback { [weak self] outcome in
            self?.handleInterceptorOutcome(message: message, outcome: outcome)
        }

        let timeoutMs = max(0, interceptor.getTimeoutMs())
        let timeoutItem = DispatchWorkItem { [weak callback] in
            callback?.timeout()
        }

        callback.setCancelTimeout { timeoutItem.cancel() }

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(timeoutMs), execute: timeoutItem)

        interceptor.onMessageLoaded(message, callback: callback)
    }

    private func handleInterceptorOutcome(message: OverlayMessagingMessage, outcome: InterceptorOutcome) {
        switch outcome {
        case .show:
            displayQueue.append(message)
            maybeShowNext()
        case .discard, .deferred, .timeout:
            onSlotCleared(message.type)
        }
        trackInterceptedEvent(messageId: message.id, outcome: outcome)
    }

    private func trackInterceptedEvent(messageId: Int64, outcome: InterceptorOutcome) {
        Optimobile.trackEventImmediately(
            eventType: OptimobileEvent.OM_INTERCEPTED.rawValue,
            properties: ["id": messageId, "outcome": outcome.eventValue]
        )
    }

    private func maybeShowNext() {
        // TODO: display view
    }
}

// MARK: - InterceptorOutcome

private enum InterceptorOutcome {
    case show, discard, deferred, timeout

    var eventValue: String {
        switch self {
        case .show: return "shown"
        case .discard: return "discarded"
        case .deferred: return "deferred"
        case .timeout: return "timeout"
        }
    }
}

// MARK: - InterceptorCallback

private class InterceptorCallback: OverlayMessagingInterceptorCallback {
    private var resolved = false
    private var cancelTimeout: (() -> Void)?
    private let onOutcome: (InterceptorOutcome) -> Void

    init(onOutcome: @escaping (InterceptorOutcome) -> Void) {
        self.onOutcome = onOutcome
    }

    func setCancelTimeout(_ cancel: @escaping () -> Void) {
        cancelTimeout = cancel
    }

    func show() { resolve(.show) }
    func discard() { resolve(.discard) }
    func deferMessage() { resolve(.deferred) }
    func timeout() { resolve(.timeout) }

    private func resolve(_ outcome: InterceptorOutcome) {
        DispatchQueue.main.async {
            guard !self.resolved else { return }
            self.resolved = true
            self.cancelTimeout?()
            self.onOutcome(outcome)
        }
    }
}
