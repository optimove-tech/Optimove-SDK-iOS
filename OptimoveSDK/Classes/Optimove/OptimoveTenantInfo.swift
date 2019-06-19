//
//  OptimoveTenantInfo.swift
//  OptimoveSDK
//
//  Created by Mobile Developer Optimove on 28/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

@objc public class OptimoveTenantInfo: NSObject {
    var url: String
    @objc public var tenantToken: String
    @objc public var configName: String

    @objc public init(
        tenantToken: String,
        configName: String
    )

    {
        self.url = "https://sdk-cdn.optimove.net/mobilesdkconfig"
        self.tenantToken = tenantToken
        self.configName = configName
    }
}
