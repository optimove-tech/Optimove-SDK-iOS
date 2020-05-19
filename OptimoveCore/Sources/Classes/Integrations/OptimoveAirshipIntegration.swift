//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

public struct OptimoveAirshipIntegration {

    struct Constants {
        static let airshipFile = "airship_file.json"
        static let isGroupContainer = true
    }

    public struct Airship: Codable, Hashable {
        let channelId: String
        let appKey: String
    }

    private let storage: OptimoveStorage
    private let configuration: Configuration

    public init(storage: OptimoveStorage,
                configuration: Configuration) {
        self.storage = storage
        self.configuration = configuration
    }

    public func obtain() throws {
        guard configuration.isSupportedAirship ?? false else {
            throw GuardError.custom("Airship integration does not supported")
        }
        guard let channelId = secretChannelIdentifier(),
            let appKey = secretAppKey() else { return }
        try storage.save(data: Airship(channelId: channelId, appKey: appKey),
                         toFileName: Constants.airshipFile,
                         isGroupContainer: Constants.isGroupContainer)
    }

    public func loadAirshipIntegration() throws -> Airship {
        guard configuration.isSupportedAirship ?? false,
            storage.isExist(fileName: Constants.airshipFile, isGroupContainer: Constants.isGroupContainer) else {
            throw GuardError.custom("Airship integration does not supported")
        }
        return try storage.load(fileName: Constants.airshipFile, isGroupContainer: Constants.isGroupContainer)
    }

    /// `[UAirship channel].identifier]`
    private func secretChannelIdentifier() -> String? {
        guard let airship = NSClassFromString("UAirship"),
            airship.responds(to: NSSelectorFromString("channel")),
            let channel = (airship as AnyObject as? NSObject)?.value(forKey: "channel") as? NSObject,
            channel.responds(to: NSSelectorFromString("identifier")) else { return nil }
        return channel.value(forKey: "identifier") as? String
    }

    /// `[UAirship shared].config.appKey`
    private func secretAppKey() -> String? {
        guard let airship = NSClassFromString("UAirship"),
            airship.responds(to: NSSelectorFromString("shared")),
            let shared = (airship as AnyObject as? NSObject)?.value(forKey: "shared") as? NSObject,
            shared.responds(to: NSSelectorFromString("config")),
            let config = shared.value(forKey: "config") as? NSObject,
            config.responds(to: NSSelectorFromString("appKey")) else { return nil }
        return config.value(forKey: "appKey") as? String
    }

}
