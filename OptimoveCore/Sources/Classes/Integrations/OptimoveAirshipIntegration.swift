//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

public class OptimoveAirshipIntegration {

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
    private var airship: Airship?

    public init(storage: OptimoveStorage,
                configuration: Configuration) {
        self.storage = storage
        self.configuration = configuration
    }

    public func loadAirshipIntegration() throws -> Airship {
        guard configuration.isSupportedAirship ?? false else {
            throw GuardError.custom("Airship integration does not supported")
        }
        if let airship = airship {
            return airship
        }
        if isAirshipExistInStorage() {
            return try load()
        }
        try obtain()
        return try load()
    }

    private func isAirshipExistInStorage() -> Bool {
        return storage.isExist(fileName: Constants.airshipFile, isGroupContainer: Constants.isGroupContainer)
    }

    private func load() throws -> Airship {
        let airship: Airship = try storage.load(
            fileName: Constants.airshipFile,
            isGroupContainer: Constants.isGroupContainer
        )
        self.airship = airship
        return airship
    }

    private func obtain() throws {
        guard let channelId = secretChannelIdentifier(), let appKey = secretAppKey() else { return }
        try storage.save(
            data: Airship(channelId: channelId, appKey: appKey),
            toFileName: Constants.airshipFile,
            isGroupContainer: Constants.isGroupContainer
        )
    }

    /// `[UAirship channel].identifier]`
    private func secretChannelIdentifier() -> String? {
        let channelProperty = "channel"
        let identifierProperty = "identifier"
        guard let airship = NSClassFromString("UAirship"),
            airship.responds(to: NSSelectorFromString(channelProperty)),
            let channel = (airship as AnyObject as? NSObject)?.value(forKey: channelProperty) as? NSObject,
            channel.responds(to: NSSelectorFromString(identifierProperty)) else { return nil }
        return channel.value(forKey: identifierProperty) as? String
    }

    /// `[UAirship shared].config.appKey`
    private func secretAppKey() -> String? {
        let sharedProperty = "shared"
        let configProperty = "config"
        let appKeyProperty = "appKey"
        guard let airship = NSClassFromString("UAirship"),
            airship.responds(to: NSSelectorFromString(sharedProperty)),
            let shared = (airship as AnyObject as? NSObject)?.value(forKey: sharedProperty) as? NSObject,
            shared.responds(to: NSSelectorFromString(configProperty)),
            let config = shared.value(forKey: configProperty) as? NSObject,
            config.responds(to: NSSelectorFromString(appKeyProperty)) else { return nil }
        return config.value(forKey: appKeyProperty) as? String
    }

}
