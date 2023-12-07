//  Copyright © 2022 Optimove. All rights reserved.

import Foundation

struct PendingNotification: Codable {
    let id: Int
    let deliveredAt: Date
    let identifier: String

    init(id: Int, deliveredAt: Date = .init(), identifier: String) {
        self.id = id
        self.deliveredAt = deliveredAt
        self.identifier = identifier
    }
}
