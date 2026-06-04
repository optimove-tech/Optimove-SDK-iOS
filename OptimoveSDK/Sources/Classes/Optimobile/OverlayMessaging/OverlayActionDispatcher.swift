//  Copyright © 2025 Optimove. All rights reserved.

import Foundation

final class OverlayActionDispatcher {

    private var handlers: [OverlayActionType: OverlayActionHandler] = [:]
    private let logError: (String) -> Void

    init(logError: @escaping (String) -> Void = { Logger.error($0) }) {
        self.logError = logError
    }

    func setHandler(_ type: OverlayActionType, _ handler: OverlayActionHandler?) {
        if let handler = handler {
            handlers[type] = handler
        } else {
            handlers.removeValue(forKey: type)
        }
    }

    /// Returns true if a handler was registered and invoked (SDK must not run its default).
    @discardableResult
    func dispatch(_ type: OverlayActionType, message: OverlayMessagingMessage, data: [String: Any]) -> Bool {
        guard let handler = handlers[type] else { return false }
        do {
            try handler(message, data)
        } catch {
            logError("Overlay action handler for \(type) threw: \(error.localizedDescription)")
        }
        return true
    }
}
