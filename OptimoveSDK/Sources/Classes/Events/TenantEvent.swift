//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

final class TenantEvent: Event {

    override init(uuid: String = UUID().uuidString,
                  name: String,
                  category: String = "global",
                  context: [String : Any],
                  timestamp: Double = Date().timeIntervalSince1970) {
        super.init(uuid: uuid, name: name, category: category, context: context, timestamp: timestamp)
    }

}
