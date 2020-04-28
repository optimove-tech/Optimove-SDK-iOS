//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

/// Builds an Optistream event from internal event type.
public final class OptistreamEventBuilder {

    struct Constants {
        struct Keys {
            static let platform = "sdk_platform"
            static let version = "sdk_version"
            static let appVersion = "app_version"
            static let osVersion = "os_version"
            static let deviceModel = "device_model"
            static let channel = "channel"
        }
        struct Values {
            static let origin = "sdk"
            static let platform = "iOS"
        }
    }

    private let configuration: OptitrackConfig
    private let storage: OptimoveStorage
    private let airshipService: AirshipService

    public init(
        configuration: OptitrackConfig,
        storage: OptimoveStorage,
        airshipService: AirshipService
    ) {
        self.configuration = configuration
        self.storage = storage
        self.airshipService = airshipService
    }

    public func build(event: Event) throws -> OptistreamEvent {
        return OptistreamEvent(
            uuid: event.uuid,
            tenant: configuration.tenantID,
            category: event.category,
            event: event.name,
            origin: Constants.Values.origin,
            customer: storage.customerID,
            visitor: try storage.getVisitorID(),
            timestamp: Formatter.iso8601withFractionalSeconds.string(from: event.timestamp),
            context: try JSON(event.context),
            metadata: try buildMetadata()
        )
    }

    private func buildMetadata() throws -> JSON {
        var metadata = try JSON([
            Constants.Keys.platform: Constants.Values.platform,
            Constants.Keys.version: SDKVersion,
            Constants.Keys.appVersion: Bundle.main.appVersion,
            Constants.Keys.osVersion: ProcessInfo.processInfo.osVersion,
            Constants.Keys.deviceModel: utsname().deviceModel
        ])
        if let airship = try? airshipService.loadAirshipIntegration() {
            metadata = metadata.merging(
                with: JSON.init(
                    dictionaryLiteral: (Constants.Keys.channel, try JSON.init(encodable: airship))
                )
            )
        }
        return metadata
    }

}
