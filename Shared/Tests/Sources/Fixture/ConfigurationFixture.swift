//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
@testable import OptimoveCore

struct Options {
    let isEnableRealtime: Bool
    let isEnableRealtimeThroughOptistream: Bool

    static var `default`: Options = .init(
        isEnableRealtime: true,
        isEnableRealtimeThroughOptistream: false
    )
}

enum ConfigurationFixture {
    static func build(_ options: Options = Options.default) -> Configuration {
        return ConfigurationBuilder(
            globalConfig: GlobalConfigFixture().build(),
            tenantConfig: TenantConfigFixture().build(options)
        ).build()
    }
}
