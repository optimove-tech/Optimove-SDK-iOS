//  Copyright © 2025 Optimove. All rights reserved.

import Foundation

struct OverlayMessagingRendererEvent {
    let type: String
    let immediateFlush: Bool
    let data: NSDictionary?
    
    static func parseAll(from raw: [Any]?) -> [OverlayMessagingRendererEvent] {
        guard let raw = raw else { return [] }
        return raw.compactMap { item -> OverlayMessagingRendererEvent? in
            guard let obj = item as? NSDictionary,
                  let type = obj["type"] as? String
            else { return nil }
            let immediateFlush = obj["immediateFlush"] as? Bool ?? true
            let data = obj["data"] as? NSDictionary
            return OverlayMessagingRendererEvent(type: type, immediateFlush: immediateFlush, data: data)
        }
    }
}
