//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

private struct Constants {
    static let category = "track"
}

class Event {
    let uuid: String
    let name: String
    let category: String
    let context: [String: Any]
    /// In seconds.
    let timestamp: Double

    internal init(uuid: String = UUID().uuidString,
                  name: String,
                  category: String = Constants.category,
                  context: [String: Any],
                  timestamp: Double = Date().timeIntervalSince1970) {
        self.uuid = uuid
        self.name = name
        self.category = category
        self.context = context
        self.timestamp = timestamp
    }

}
