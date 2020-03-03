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
        let token = try storage.getApnsToken()
        let tokenToStringFormat = "%02.2hhx"
        return Installation(
            customerID: storage.customerID,
            deviceToken: token.map { String(format: tokenToStringFormat, $0) }.joined(),
            installationID: try storage.getInstallationID(),
            appNS: appNamespace,
            visitorID: try storage.getInitialVisitorId(),
            optIn: storage.optFlag,
            isDev: AppEnvironment.isSandboxAps,
            metadata: metadata,
            isPushCampaignsDisabled: storage.arePushCampaignsDisabled
        )
    }

}

private extension Bundle {

    var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "undefined"
    }

}

private extension utsname {

    var deviceModel: String {
        var systemInfo = self
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }

}

private extension ProcessInfo {

    var osVersion: String {
        [
            self.operatingSystemVersion.majorVersion,
            self.operatingSystemVersion.minorVersion,
            self.operatingSystemVersion.patchVersion
        ].map { String($0) }.joined(separator: ".")
    }

}
