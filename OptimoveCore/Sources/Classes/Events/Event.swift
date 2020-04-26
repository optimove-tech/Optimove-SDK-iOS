//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

open class Event {

    public struct Constants {
        public static let category = "track"
    }

    public let uuid: String
    public let name: String
    public let category: String
    public let context: [String: Any]
    public let timestamp: Int
    public let isRealtime: Bool

    public init(
        uuid: String = UUID().uuidString,
        name: String,
        category: String = Constants.category,
        context: [String: Any],
        timestamp: Int = Date().timeIntervalSince1970.seconds,
        isRealtime: Bool = false) {
        self.uuid = uuid
        self.name = name
        self.category = category
        self.context = context
        self.timestamp = timestamp
        self.isRealtime = isRealtime
    }

}
