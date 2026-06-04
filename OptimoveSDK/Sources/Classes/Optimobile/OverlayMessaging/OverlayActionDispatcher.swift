//  Copyright © 2025 Optimove. All rights reserved.

import Foundation

/// Internal representation of an overlay action routed from IAR to a handler method.
enum OverlayAction {
    case linkAction(LinkActionPayload)
}

/// Dispatches actions to `handlers ?? defaults` so unoverridden actions fall back to the SDK default.
final class OverlayActionDispatcher {

    private let defaults: OverlayActionHandler
    private var handlers: OverlayActionHandler
    private let logError: (String) -> Void

    init(defaults: OverlayActionHandler, logError: @escaping (String) -> Void = { Logger.error($0) }) {
        self.defaults = defaults
        self.handlers = defaults
        self.logError = logError
    }

    func setOverrides(_ handlers: OverlayActionHandler?) {
        self.handlers = handlers ?? defaults
    }

    func dispatch(_ action: OverlayAction, message: OverlayMessagingMessage) {
        do {
            switch action {
            case .linkAction(let payload):
                try handlers.linkAction(message: message, payload: payload)
            }
        } catch {
            logError("Overlay action handler threw: \(error.localizedDescription)")
        }
    }
}
