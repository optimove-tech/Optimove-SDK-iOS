//  Copyright © 2026 Optimove. All rights reserved.

import Foundation

public struct TenantGamifyConfig: Codable, Equatable {
    public let adactUrl: String?
    public let loyaltyWidgetUrl: String?

    public init(adactUrl: String? = nil, loyaltyWidgetUrl: String? = nil) {
        self.adactUrl = adactUrl
        self.loyaltyWidgetUrl = loyaltyWidgetUrl
    }
}
