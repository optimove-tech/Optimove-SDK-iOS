//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

open class Event {

    public static let category = "track"

    public let eventId: UUID
    public let name: String
    public let timestamp: Date
    public let category: String
    public var context: [String: Any]
    public var isRealtime: Bool
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

public struct ValidationIssue: Codable, Hashable {

    private struct Constants {
        static let errorStatuses = [
            1_010,
            1_040,
            1_050,
            1_060,
            1_070,
            1_080
        ]
    }

    public let status: Int
    public let message: String

    public init(status: Int, message: String) {
        self.status = status
        self.message = message
    }

    public var isError: Bool {
        return Constants.errorStatuses.contains(status)
    }
}
