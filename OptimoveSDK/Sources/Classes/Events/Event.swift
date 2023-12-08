//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

class Event {
    static let category = "track"

    let eventId: UUID
    let requestId: String
    let name: String
    let timestamp: Date
    let category: String
    var context: [String: Any]
    var isRealtime: Bool

    init(
        eventId: UUID? = nil,
        requestId: String? = nil,
        name: String,
        category: String = category,
        context: [String: Any],
        timestamp: Date = Date(),
        isRealtime: Bool = false
    ) {
        let uuid = UUID()
        self.eventId = eventId ?? uuid
        self.requestId = requestId ?? uuid.uuidString
        self.name = name
        self.category = category
        self.context = context
        self.timestamp = timestamp
        self.isRealtime = isRealtime
    }
}
