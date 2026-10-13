//  Copyright © 2026 Optimove. All rights reserved.

import Foundation

/// Parameters for opening the loyalty widget from the configured `loyaltyWidgetUrl`.
///
/// Maps to the Web SDK `openWidget({ userId, brand })` contract:
/// `{loyaltyWidgetUrl}/{tenantId}[/brand/{brand}]/{userId}`
public struct OpenLoyaltyWidgetParams {
    public var userId: String?
    public var brand: String?

    public init(userId: String? = nil, brand: String? = nil) {
        self.userId = userId
        self.brand = brand
    }
}
