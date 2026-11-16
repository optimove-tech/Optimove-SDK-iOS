//  Copyright © 2025 Optimove. All rights reserved.

import Foundation

/// Orchestrates the overlay lifecycle: fetch -> interceptor -> queue -> display.
/// Scheduled (session) fetches are started by the session manager, which runs one at a time; each ends with exactly
/// one `release` to it. Immediate fetches have their own slot here. Both feed the same presentation queue.
class OverlayMessagingManager {
    
    private static let immediateSlotCapacity = 1
    
    private var immediateSlotCount = 0
    
    private var displayQueue: [OverlayMessagingMessage] = []
    private let requestService: OverlayMessagingRequestService
    private let sessionManager: OverlayMessagingSessionManager
    private let trackEventImmediately: (String, [String: Any]?) -> Void
    private let urlBuilder: UrlBuilder
    private var interceptor: OverlayMessagingInterceptor?
    private let actionDispatcher = OverlayActionDispatcher(defaults: DefaultOverlayActionHandler())
    private var closedListener: OverlayClosedListener?
    private var presenter: OverlayMessagingPresenter?
    private var hidden = false
    // Prevents showing the same message twice if triggers fire in quick succession
    // (after slot cleared but before backend state updates)
    private var seenMessageIds = Set<Int64>()
    
    init(httpClient: KSHttpClient, urlBuilder: UrlBuilder, sessionManager: OverlayMessagingSessionManager,
         trackEventImmediately: @escaping (String, [String: Any]?) -> Void = Optimobile.trackEventImmediately(eventType:properties:)) {
        requestService = OverlayMessagingRequestService(httpClient: httpClient)
        self.urlBuilder = urlBuilder
        self.sessionManager = sessionManager
        self.trackEventImmediately = trackEventImmediately
    }
    
    // MARK: - Interceptor
    
    func setInterceptor(_ interceptor: OverlayMessagingInterceptor?) {
        self.interceptor = interceptor
    }

    func setActionHandler(_ handler: OverlayActionHandler?) {
        actionDispatcher.setOverrides(handler)
    }

    func setClosedListener(_ listener: OverlayClosedListener?) {
        closedListener = listener
    }

    // MARK: - Visibility

    func setHidden(_ hidden: Bool) {
        guard self.hidden != hidden else { return }
        self.hidden = hidden

        if hidden {
            presenter?.setHidden(true)
        } else {
            maybeShowNext()
            presenter?.setHidden(false)
        }
    }
    
    // MARK: - Triggers
    
    /// A scheduled trigger only ever comes from the session manager, with its slot taken for us; an immediate one
    /// takes the immediate slot here.
    func onTriggerReceived(_ type: OverlayMessagingMessage.MessageType) {
        switch type {
        case .session:
            requestService.readScheduledMessage { result in
                DispatchQueue.main.async {
                    self.sessionManager.onFetchResult(nextFetchInSeconds: result.nextFetchInSeconds)
                    self.onMessageLoaded(type: type, message: result.message)
                }
            }
        case .immediate:
            guard immediateSlotCount < Self.immediateSlotCapacity else {
                return
            }
            immediateSlotCount += 1
            requestService.readOverlayMessage(type: type) { message in
                DispatchQueue.main.async {
                    self.onMessageLoaded(type: type, message: message)
                }
            }
        }
    }
    
    // MARK: - Slots
    
    /// Frees the slot of a message's type: for a scheduled one, the session manager's, saying how it ended and, if it
    /// was displayed, which message, so a later display of it counts again.
    private func release(_ type: OverlayMessagingMessage.MessageType, _ outcome: OverlayMessagingSessionManager.Outcome,
                         displayedMessageId: Int64? = nil) {
        switch type {
        case .session:
            sessionManager.release(outcome, displayedMessageId: displayedMessageId)
        case .immediate:
            immediateSlotCount = max(0, immediateSlotCount - 1)
        }
    }
    
    // MARK: - Loading
    
    private func onMessageLoaded(type: OverlayMessagingMessage.MessageType, message: OverlayMessagingMessage?) {
        guard let message = message else {
            release(type, .done)
            return
        }
        guard !seenMessageIds.contains(message.id) else {
            release(type, .deferred)
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
        let timeoutItem = DispatchWorkItem {
            callback.timeout()
        }
        
        callback.setCancelTimeout { timeoutItem.cancel() }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(timeoutMs), execute: timeoutItem)
        
        interceptor.onMessageLoaded(message, callback: callback)
    }
    
    private func handleInterceptorOutcome(message: OverlayMessagingMessage, outcome: InterceptorOutcome) {
        trackInterceptedEvent(messageId: message.id, outcome: outcome)
        switch outcome {
        case .show:
            displayQueue.append(message)
            maybeShowNext()
        case .deferred, .timeout:
            seenMessageIds.remove(message.id)
            release(message.type, .deferred)
        case .discard:
            // The server deletes the message when it gets this event; the session manager's settle delay gives it time
            release(message.type, .done)
        }
    }
    
    private func trackInterceptedEvent(messageId: Int64, outcome: InterceptorOutcome) {
        trackEventImmediately(OptimobileEvent.OM_INTERCEPTED.rawValue, ["id": messageId, "outcome": outcome.eventValue])
    }
    
    // MARK: - Display
    
    private func maybeShowNext() {
        guard !hidden else { return }

        guard let next = displayQueue.first else {
            presenter?.dispose()
            presenter = nil
            return
        }
        
        if let presenter = presenter {
            presenter.showMessage(next)
            return
        }

        presenter = OverlayMessagingPresenter(
            message: next,
            urlBuilder: urlBuilder,
            delegate: self
        )
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
    
    func onMessageOpened(_ message: OverlayMessagingMessage) {
        if message.type == .session {
            sessionManager.onDisplayed(messageId: message.id)
        }
    }

    func onMessageClosed(_ message: OverlayMessagingMessage, reason: OverlayCloseReason) {
        guard isFrontOfQueue(message) else { return }
        displayQueue.removeFirst()
        release(message.type, .done, displayedMessageId: message.id)
        closedListener?(message, OverlayClosedInfo(reason: reason))
        maybeShowNext()
    }

    func onEvents(_ message: OverlayMessagingMessage, events: [OverlayMessagingRendererEvent]) {
        trackRendererEvents(messageId: message.id, events: events)
    }

    func onAction(_ message: OverlayMessagingMessage, action: OverlayAction) {
        actionDispatcher.dispatch(action, message: message)
    }

    func onViewError(_ message: OverlayMessagingMessage) {
        // Checked before disposing: a stale error must not tear down the presenter now showing the next message.
        guard isFrontOfQueue(message) else { return }
        presenter?.dispose()
        presenter = nil
        // Immediate messages are short-lived. In case of an error we dont want them to stay on queue and surface later
        displayQueue.removeFirst()
        // Still on the server: fetching again at once would return it again
        release(message.type, .deferred, displayedMessageId: message.id)
        closedListener?(message, OverlayClosedInfo(reason: .error))
        maybeShowNext()
    }

    /// A presenter can report more than one close or error for the same message (e.g. a navigation
    /// failure followed by a web content process termination). Only the first one for the message
    /// at the front of the queue counts; repeats would otherwise drop the next message and free its slot.
    private func isFrontOfQueue(_ message: OverlayMessagingMessage) -> Bool {
        displayQueue.first?.id == message.id
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
