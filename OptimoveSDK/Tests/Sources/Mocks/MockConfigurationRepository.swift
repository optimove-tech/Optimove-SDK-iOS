//  Copyright © 2019 Optimove. All rights reserved.

import OptimoveCore

final class MockConfigurationRepository: ConfigurationRepository {
    var configuration: Configuration?
    var global: GlobalConfig?
    var tenant: TenantConfig?

    func getConfiguration() throws -> Configuration {
        return try unwrap(configuration)
    }

    func setConfiguration(_ config: Configuration) throws {
        configuration = config
    }

    func getGlobal() throws -> GlobalConfig {
        return try unwrap(global)
    }

    func saveGlobal(_ config: GlobalConfig) throws {
        global = config
    }

    func getTenant() throws -> TenantConfig {
        return try unwrap(tenant)
    }

    func saveTenant(_ config: TenantConfig) throws {
        tenant = config
    }
}
