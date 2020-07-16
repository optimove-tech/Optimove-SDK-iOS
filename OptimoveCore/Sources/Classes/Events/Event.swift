//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

open class Event {

    public static let category = "track"

    public let eventId: UUID
    public let name: String
    public let category: String
    public let context: [String: Any]
    public let timestamp: Date
    public let isRealtime: Bool
    public var validations: [ValidationIssue]

    public init(
        eventId: UUID = UUID(),
        name: String,
        category: String = category,
        context: [String: Any],
        timestamp: Date = Date(),
        isRealtime: Bool = false,
        validations: [ValidationIssue] = []
    ) {
        self.eventId = eventId
        self.name = name
        self.category = category
        self.context = context
        self.timestamp = timestamp
        self.isRealtime = isRealtime
        self.validations = validations
    }

}

public struct ValidationIssue: Encodable {
    public let status: Int
    public let message: String
}
