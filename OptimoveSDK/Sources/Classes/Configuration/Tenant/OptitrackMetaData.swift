//  Copyright © 2017 Optimove. All rights reserved.

import Foundation

struct TenantOptitrackConfig: Codable, Equatable {
    var optitrackEndpoint: URL
    var siteId: Int

    init(
        optitrackEndpoint: URL,
        siteId: Int
    ) {
        self.optitrackEndpoint = optitrackEndpoint
        self.siteId = siteId
    }
}
