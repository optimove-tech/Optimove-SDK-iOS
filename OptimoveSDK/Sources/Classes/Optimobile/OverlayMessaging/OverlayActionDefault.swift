//  Copyright © 2025 Optimove. All rights reserved.

import UIKit

/// SDK default implementations for every overlay action method. Any method a client does not
/// override in their own `OverlayActionHandler` conformer falls back to these automatically.
public extension OverlayActionHandler {
    func linkAction(message: OverlayMessagingMessage, payload: LinkActionPayload) {
        guard let url = URL(string: payload.url) else { return }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
}

/// Empty conformer used internally as the nil-fallback; all methods use the protocol extension defaults above.
final class DefaultOverlayActionHandler: OverlayActionHandler {}
