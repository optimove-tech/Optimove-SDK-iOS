//  Copyright © 2017 Optimove. All rights reserved.

import Foundation

public struct TenantOptitrackConfig: Codable, Equatable {
    public var optitrackEndpoint: URL
    public var siteId: Int
    public var maxActionCustomDimensions: Int

    public init(
        optitrackEndpoint: URL,
        siteId: Int,
        maxActionCustomDimensions: Int
    ) {
        self.optitrackEndpoint = optitrackEndpoint
        self.siteId = siteId
        self.maxActionCustomDimensions = maxActionCustomDimensions
    }
}
