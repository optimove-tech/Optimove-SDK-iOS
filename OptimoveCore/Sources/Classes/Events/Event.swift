//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

open class Event {

    public enum EventType {
        case core
        case custom
    }

    public struct Constants {
        public static let category = "track"
    }

    public let uuid: String
    public let name: String
    public let category: String
    public let context: [String: Any]
    public let timestamp: Date
    public let isRealtime: Bool
    public let type: Event.EventType

    public init(
        uuid: String = UUID().uuidString,
        name: String,
        category: String = Constants.category,
        context: [String: Any],
        timestamp: Date = Date(),
        isRealtime: Bool = false,
        type: Event.EventType = .core
    ) {
        self.uuid = uuid
        self.name = name
        self.category = category
        self.context = context
        self.timestamp = timestamp
        self.isRealtime = isRealtime
        self.type = type
    }

}
