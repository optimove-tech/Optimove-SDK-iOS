//  Copyright © 2025 Optimove. All rights reserved.

import UIKit

/// SDK default implementations for every overlay action method. Any method a client does not
/// override in their own `OverlayActionHandlers` conformer falls back to these automatically.
public extension OverlayActionHandlers {
    func linkAction(message: OverlayMessagingMessage, data: LinkActionData) {
        guard let url = URL(string: data.url) else { return }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
}

/// Empty conformer used internally as the nil-fallback; all methods use the protocol extension defaults above.
final class DefaultOverlayActionHandlers: OverlayActionHandlers {}
