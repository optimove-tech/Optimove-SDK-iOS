//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class NewTenantInfoHandler {

    private var storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    /// Stores the user information that was provided during configuration.
    ///
    /// - Parameter info: user unique info
    func handle(_ info: OptimoveTenantInfo) {
        storage.tenantToken = info.tenantToken
        storage.version = info.configName
        storage.configurationEndPoint = Endpoints.Remote.TenantConfig.url
        Logger.info(
            """
            Stored user info in local storage.
            Source:
            endpoint: \(Endpoints.Remote.TenantConfig.url.absoluteString)
            token: \(info.tenantToken)
            version: \(info.configName)
            """
        )
    }

}
