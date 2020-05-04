//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class RealTimeEventBuilder {

    private let storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

    func createEvent(context: RealTimeEventContext, realtimeToken: String) throws -> RealtimeEvent {
        let customerID: String? = storage[.customerID]
        let visitorID: String? = context.type == .setUserID ? storage[.initialVisitorId] : storage[.visitorID]

        if (customerID ?? visitorID) == nil {
            throw RealTimeError.eitherCustomerOrVisitorIdIsNil
        }

        return try RealtimeEvent(
            tid: realtimeToken,
            cid: customerID,
            visitorId: visitorID,
            eid: String(context.config.id),
            context: context.event.context,
            firstVisitorDate: storage[.firstVisitTimestamp] ?? 0
        )
    }

}
