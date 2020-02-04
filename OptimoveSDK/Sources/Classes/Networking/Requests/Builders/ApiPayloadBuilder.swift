//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ApiPayloadBuilder {

    private let storage: OptimoveStorage
    private let appNamespace: String

    init(storage: OptimoveStorage,
         appNamespace: String) {
        self.storage = storage
        self.appNamespace = appNamespace
    }

    func createSetUser() throws -> SetUser {
        let token = try storage.getApnsToken()
        let tokenToStringFormat = "%02.2hhx"
        return SetUser(
            deviceID: try storage.getInstallationID(),
            appNS: appNamespace,
            os: SetUser.Constants.os,
            deviceToken: token.map { String(format: tokenToStringFormat, $0) }.joined(),
            optIn: storage.optFlag,
            isDev: AppEnvironment.isSandboxAps
        )
    }

}
