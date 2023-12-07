//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

open class Event {
    public static let category = "track"

    public let eventId: UUID
    public let requestId: String
    public let name: String
    public let timestamp: Date
    public let category: String
    public var context: [String: Any]
    public var isRealtime: Bool

    public init(
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
