//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
@testable import OptimoveCore

final class ConfigurationFixture {

    static func build() -> Configuration {
        return ConfigurationBuilder(
            globalConfig: GlobalConfigFixture().build(),
            tenantConfig: TenantConfigFixture().build()
        ).build()
    }

}
