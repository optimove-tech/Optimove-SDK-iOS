//  Copyright © 2017 Optimove. All rights reserved.

import Foundation

public struct TenantOptipushConfig: Codable, Equatable {
    public let pushTopicsRegistrationEndpoint: URL
    public let enableAdvertisingIdReport: Bool

    public init(pushTopicsRegistrationEndpoint: URL, enableAdvertisingIdReport: Bool) {
        self.pushTopicsRegistrationEndpoint = pushTopicsRegistrationEndpoint
        self.enableAdvertisingIdReport = enableAdvertisingIdReport
    }

    enum CodingKeys: String, CodingKey {
        case enableAdvertisingIdReport
        case pushTopicsRegistrationEndpoint
    }
}
