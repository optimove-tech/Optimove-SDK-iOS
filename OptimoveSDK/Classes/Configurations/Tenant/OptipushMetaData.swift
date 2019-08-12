//  Copyright © 2017 Optimove. All rights reserved.

import Foundation

struct TenantOptipushConfig: Codable {
    let pushTopicsRegistrationEndpoint: URL
    let enableAdvertisingIdReport: Bool

    enum CodingKeys: String, CodingKey {
        case enableAdvertisingIdReport
        case pushTopicsRegistrationEndpoint
    }
}
