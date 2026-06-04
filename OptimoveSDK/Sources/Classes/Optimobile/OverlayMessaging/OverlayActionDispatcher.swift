//  Copyright © 2025 Optimove. All rights reserved.

import Foundation

/// Internal representation of an overlay action routed from IAR to a handler method.
enum OverlayAction {
    case linkAction(LinkActionData)
}

/// Dispatches actions to `handlers ?? defaults` so unoverridden actions fall back to the SDK default.
final class OverlayActionDispatcher {

    private let defaults: OverlayActionHandlers
    private var handlers: OverlayActionHandlers
    private let logError: (String) -> Void

    init(defaults: OverlayActionHandlers, logError: @escaping (String) -> Void = { Logger.error($0) }) {
        self.defaults = defaults
        self.handlers = defaults
        self.logError = logError
    }

    func setOverrides(_ handlers: OverlayActionHandlers?) {
        self.handlers = handlers ?? defaults
    }

    func dispatch(_ action: OverlayAction, message: OverlayMessagingMessage) {
        do {
            switch action {
            case .linkAction(let data):
                try handlers.linkAction(message: message, data: data)
            }
        } catch {
            logError("Overlay action handler threw: \(error.localizedDescription)")
        }
    }
}
