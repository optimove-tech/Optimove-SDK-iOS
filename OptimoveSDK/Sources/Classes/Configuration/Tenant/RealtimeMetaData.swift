//  Copyright © 2017 Optimove. All rights reserved.

import Foundation

public struct TenantRealtimeConfig: Codable, Equatable {
    public var realtimeGateway: URL

    public init(realtimeGateway: URL) {
        self.realtimeGateway = realtimeGateway
    }
}
