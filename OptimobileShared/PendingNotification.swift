//  Copyright © 2022 Optimove. All rights reserved.

import Foundation

internal struct PendingNotification: Codable {
    let id: Int
    let deliveredAt: Date
    let identifier: String
}
