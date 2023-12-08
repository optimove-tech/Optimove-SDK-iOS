//  Copyright © 2022 Optimove. All rights reserved.

import Foundation

public struct PendingNotification: Codable {
    public let id: Int
    public let deliveredAt: Date
    public let identifier: String

    public init(id: Int, deliveredAt: Date = .init(), identifier: String) {
        self.id = id
        self.deliveredAt = deliveredAt
        self.identifier = identifier
    }
}
