//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

open class Event {

    public static let category = "track"

    public let uuid: UUID
    public let name: String
    public let category: String
    public let context: [String: Any]
    public let timestamp: Date
    public let isRealtime: Bool

    public init(
        uuid: UUID = UUID(),
        name: String,
        category: String = category,
        context: [String: Any],
        timestamp: Date = Date(),
        isRealtime: Bool = false
    ) {
        self.uuid = uuid
        self.name = name
        self.category = category
        self.context = context
        self.timestamp = timestamp
        self.isRealtime = isRealtime
    }

}
