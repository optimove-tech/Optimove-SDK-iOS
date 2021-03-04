//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ApiPayloadBuilder {

    private let storage: OptimoveStorage
    private let appNamespace: String
    private let metadata: Installation.Metadata

    init(storage: OptimoveStorage,
         appNamespace: String) {
        self.storage = storage
        self.appNamespace = appNamespace
        self.metadata = Installation.Metadata(
            sdkVersion: Optimove.version,
            appVersion: Bundle.main.appVersion,
            osVersion: ProcessInfo.processInfo.osVersion,
            deviceModel: utsname().deviceModel
        )
    }

    func createInstallation() throws -> Installation {
        return Installation(
            customerID: storage.customerID,
            deviceToken: try storage.getApnsTokenString(),
            installationID: try storage.getInstallationID(),
            appNS: appNamespace,
            visitorID: try storage.getInitialVisitorId(),
            optIn: storage.optFlag,
            isDev: AppEnvironment.isSandboxAps,
            metadata: metadata,
            isPushCampaignsDisabled: storage.arePushCampaignsDisabled,
            firstRunTime: try storage.getFirstRunTimestamp(),
            pushNotificationChannels: storage.pushNotificationChannels
        )
    }

}
