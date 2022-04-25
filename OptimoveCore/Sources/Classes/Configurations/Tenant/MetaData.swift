//  Copyright © 2017 Optimove. All rights reserved.

import Foundation

public struct TenantOptipushConfig: Codable, Equatable {
    public let enableAdvertisingIdReport: Bool

    public init(enableAdvertisingIdReport: Bool) {
        self.enableAdvertisingIdReport = enableAdvertisingIdReport
    }

    enum CodingKeys: String, CodingKey {
        case enableAdvertisingIdReport
    }
}
