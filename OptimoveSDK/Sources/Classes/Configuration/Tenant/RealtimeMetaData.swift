//  Copyright © 2017 Optimove. All rights reserved.

import Foundation

struct TenantRealtimeConfig: Codable, Equatable {
    var realtimeGateway: URL

    init(realtimeGateway: URL) {
        self.realtimeGateway = realtimeGateway
    }
}
