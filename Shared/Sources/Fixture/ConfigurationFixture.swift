//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
@testable import OptimoveCore

public struct Options {
    public let isEnableRealtime: Bool
    public let isEnableRealtimeThroughOptistream: Bool

    public init(
        isEnableRealtime: Bool,
        isEnableRealtimeThroughOptistream: Bool
    ) {
        self.isEnableRealtime = isEnableRealtime
        self.isEnableRealtimeThroughOptistream = isEnableRealtimeThroughOptistream
    }

    public static var `default`: Options = .init(
        isEnableRealtime: true,
        isEnableRealtimeThroughOptistream: false
    )
}

public enum ConfigurationFixture {
    public static func build(_ options: Options = Options.default) -> Configuration {
        return ConfigurationBuilder(
            globalConfig: GlobalConfigFixture().build(),
            tenantConfig: TenantConfigFixture().build(options)
        ).build()
    }
}
