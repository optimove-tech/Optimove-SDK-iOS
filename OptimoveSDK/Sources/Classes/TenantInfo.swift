//
//  tenantInfo.swift
//  OptimoveSDK
//
//  Created by Barak Ben Hur on 20/04/2022.
//

import UIKit

public struct TenantInfo {
    public let apiKey: String, secretKey: String, tenantToken: String, configName: String
    
    public init(apiKey: String, secretKey: String, tenantToken: String, configName: String) {
        self.apiKey = apiKey
        self.secretKey = secretKey
        self.tenantToken = tenantToken
        self.configName = configName
    }
}
