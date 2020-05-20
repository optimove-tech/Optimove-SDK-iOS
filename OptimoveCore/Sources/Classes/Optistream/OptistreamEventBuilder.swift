//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

/// Builds an Optistream event from internal event type.
public final class OptistreamEventBuilder {

    struct Constants {
        struct Values {
            static let origin = "sdk"
        }
    }

    private let configuration: OptitrackConfig
    private let storage: OptimoveStorage
    private let airshipIntegration: OptimoveAirshipIntegration

    public init(
        configuration: OptitrackConfig,
        storage: OptimoveStorage,
        airshipIntegration: OptimoveAirshipIntegration
    ) {
        self.configuration = configuration
        self.storage = storage
        self.airshipIntegration = airshipIntegration
    }

    public func build(event: Event) throws -> OptistreamEvent {
        return OptistreamEvent(
            tenant: configuration.tenantID,
            category: event.category,
            event: event.name,
            origin: Constants.Values.origin,
            customer: storage.customerID,
            visitor: try storage.getVisitorID(),
            timestamp: event.timestamp,
            context: try JSON(event.context),
            metadata: OptistreamEvent.Metadata(
                channel: OptistreamEvent.Metadata.Channel(
                    airship: try? airshipIntegration.loadAirshipIntegration()
                ),
                realtime: event.isRealtime,
                firstVisitorDate: try storage.getFirstVisitTimestamp(),
                uuid: event.uuid
            )
        )
    }

}
