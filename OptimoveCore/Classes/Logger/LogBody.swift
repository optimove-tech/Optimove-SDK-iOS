//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public struct LogBody {
    let tenantId: Int
    let appNs: String
    let sdkEnv: Environment
    let sdkPlatform: SdkPlatform
    let level: LogLevel
    let logModule: String?
    let logFileName: String?
    let logMethodName: String?
    let message: String

    public init(
        tenantId: Int,
        appNs: String,
        sdkEnv: Environment,
        sdkPlatform: SdkPlatform,
        level: LogLevel,
        logModule: String?,
        logFileName: String?,
        logMethodName: String?,
        message: String
    ) {
        self.tenantId = tenantId
        self.appNs = appNs
        self.sdkEnv = sdkEnv
        self.sdkPlatform = sdkPlatform
        self.level = level
        self.logModule = logModule
        self.logFileName = logFileName
        self.logMethodName = logMethodName
        self.message = message
    }
}

extension LogBody: Codable {}
