//  Copyright © 2020 Optimove. All rights reserved.

/// Builds an Optistream event from internal event type.
public final class OptistreamEventBuilder {

    struct Constants {
        static let origin = "sdk"
    }

    private let configuration: OptitrackConfig
    private let storage: OptimoveStorage

    public init(
        configuration: OptitrackConfig,
        storage: OptimoveStorage
    ) {
        self.configuration = configuration
        self.storage = storage
    }

    public func build(event: Event) throws -> OptistreamEvent {
        return OptistreamEvent(
            uuid: event.uuid,
            tenant: configuration.tenantID,
            category: event.category,
            event: event.name,
            origin: Constants.origin,
            customer: storage.customerID,
            visitor: try storage.getVisitorID(),
            timestamp: event.timestamp,
            context: try JSON(event.context)
        )
    }

}
