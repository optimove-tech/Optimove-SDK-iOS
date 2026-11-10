//  Copyright © 2026 Optimove. All rights reserved.

import Foundation

/// Decides which tile stays when more than one live tile has the same Optimove activity id.
/// iOS has no dedupe for push-to-start, so a repeated start shows a second tile.
/// The first live tile seen for a key is kept for as long as it stays live.
struct LiveActivityDuplicateResolver {
    private var keptActivityIds: [String: String] = [:]

    /// Returns the id of the tile to keep for `key`. `liveActivityIds` holds the live tiles for `key`.
    mutating func activityToKeep(activityId: String, key: String, liveActivityIds: Set<String>) -> String {
        if let kept = keptActivityIds[key], kept != activityId, liveActivityIds.contains(kept) {
            return kept
        }

        keptActivityIds[key] = activityId
        return activityId
    }
}
