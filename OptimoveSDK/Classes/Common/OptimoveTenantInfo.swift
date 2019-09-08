//  Copyright © 2017 Optimove. All rights reserved.

import Foundation

@objc public class OptimoveTenantInfo: NSObject {

    @objc public var tenantToken: String
    @objc public var configName: String

    @objc public init(tenantToken: String, configName: String) {
        self.tenantToken = tenantToken
        self.configName = configName
    }
}
