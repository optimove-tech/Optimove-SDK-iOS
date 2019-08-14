//  Copyright © 2017 Optimove. All rights reserved.

import Foundation

public struct TenantRealtimeConfig: Codable {
    public var realtimeToken: String
    public var realtimeGateway: URL

    public init(realtimeToken: String, realtimeGateway: URL) {
        self.realtimeToken = realtimeToken
        self.realtimeGateway = realtimeGateway
    }
}
