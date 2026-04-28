//  Copyright © 2025 Optimove. All rights reserved.

import Foundation

class OverlayMessagingManager {
    
    private static let sessionSlotCapacity = 1
    private static let immediateSlotCapacity = 1
    
    private var sessionSlotCount = 0
    private var immediateSlotCount = 0
    
    private var displayQueue: [OverlayMessagingMessage] = []
    private let requestService: OverlayMessagingRequestService
    private let urlBuilder: UrlBuilder
    private var interceptor: OverlayMessagingInterceptor?
    private var presenter: OverlayMessagingPresenter?
    // Prevents showing the same message twice if triggers fire in quick succession
    // (after slot cleared but before backend state updates)
    private var seenMessageIds = Set<Int64>()
    
    init(httpClient: KSHttpClient, urlBuilder: UrlBuilder) {
        requestService = OverlayMessagingRequestService(httpClient: httpClient)
        self.urlBuilder = urlBuilder
    }
    
    // MARK: - Interceptor
    
    func setInterceptor(_ interceptor: OverlayMessagingInterceptor?) {
        self.interceptor = interceptor
    }
    
    // MARK: - Triggers
    
    func onTriggerReceived(_ type: OverlayMessagingMessage.MessageType) {
        
        switch type {
        case .session:
            guard sessionSlotCount < Self.sessionSlotCapacity else {
                return
            }
            sessionSlotCount += 1
            loadMessage(type)
        case .immediate:
            guard immediateSlotCount < Self.immediateSlotCapacity else {
                return
            }
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
        guard !seenMessageIds.contains(message.id) else {
            onSlotCleared(type)
            return
        }
        seenMessageIds.insert(message.id)
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
        case .deferred, .timeout:
            seenMessageIds.remove(message.id)
            onSlotCleared(message.type)
        case .discard:
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
    
    // MARK: - Display
    
    private func maybeShowNext() {
        guard let next = displayQueue.first else {
            presenter?.dispose()
            presenter = nil
            return
        }
        
        if let presenter = presenter {
            presenter.showMessage(next)
            return
        }
        
        presenter = OverlayMessagingPresenter(message: next, urlBuilder: urlBuilder, delegate: self)
    }
    
    // MARK: - Event tracking
    
    private func trackRendererEvents(messageId: Int64, events: [OverlayMessagingRendererEvent]) {
        for event in events {
            var props: [String: Any] = event.data.flatMap { $0 as? [String: Any] } ?? [:]
            props["id"] = messageId
            Optimobile.trackEvent(
                eventType: event.type,
                atTime: Date(),
                properties: props,
                immediateFlush: event.immediateFlush
            )
        }
    }
    
}

// MARK: - OverlayMessagingPresenterDelegate

extension OverlayMessagingManager: OverlayMessagingPresenterDelegate {
    
    func onMessageClosed(_ message: OverlayMessagingMessage) {
        if !displayQueue.isEmpty { displayQueue.removeFirst() }
        onSlotCleared(message.type)
        maybeShowNext()
    }

    func onEvents(_ message: OverlayMessagingMessage, events: [OverlayMessagingRendererEvent]) {
        trackRendererEvents(messageId: message.id, events: events)
    }

    func onViewError(_ message: OverlayMessagingMessage) {
        presenter?.dispose()
        presenter = nil
        // Immediate messages are short-lived. In case of an error we dont want them to stay on queue and surface later
        if !displayQueue.isEmpty { displayQueue.removeFirst() }
        onSlotCleared(message.type)
        maybeShowNext()
    }
}

// MARK: - InterceptorOutcome

private enum InterceptorOutcome {
    case show, discard, deferred, timeout
    
    var eventValue: String {
        switch self {
        case .show: return "show"
        case .discard: return "discard"
        case .deferred: return "defer"
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
