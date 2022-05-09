//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

/// Builds an Optistream event from internal event type.
/// The `delivery_event` do not use this class in reason of memory consuption under Notification Service Extention.
public final class OptistreamEventBuilder {

    struct Constants {
        struct Values {
            static let origin = "sdk"
        }
    }

    private let tenantID: Int
    private let storage: OptimoveStorage

    public init(
        tenantID: Int,
        storage: OptimoveStorage
    ) {
        self.tenantID = tenantID
        self.storage = storage
    }

    public func build(event: Event) throws -> OptistreamEvent {
        return OptistreamEvent(
            tenant: tenantID,
            category: event.category,
            event: event.name,
            origin: Constants.Values.origin,
            customer: storage.customerID,
            visitor: try storage.getVisitorID(),
            timestamp: Formatter.iso8601withFractionalSeconds.string(from: event.timestamp),
            context: try JSON(event.context),
            metadata: OptistreamEvent.Metadata(
                realtime: event.isRealtime,
                firstVisitorDate: try storage.getFirstRunTimestamp(),
                eventId: event.eventId.uuidString,
                requestId: event.requestId
            )
        )
    }

}
