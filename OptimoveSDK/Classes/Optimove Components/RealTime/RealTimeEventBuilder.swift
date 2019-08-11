// Copiright 2019 Optimove

import Foundation

final class RealTimeEventBuilder {

    private let metaDataProvider: MetaDataProvider<RealtimeMetaData>
    private let storage: OptimoveStorage

    init(metaDataProvider: MetaDataProvider<RealtimeMetaData>,
         storage: OptimoveStorage) {
        self.metaDataProvider = metaDataProvider
        self.storage = storage
    }

    func createEvent(context: RealTimeEventContext) throws -> RealtimeEvent {
        let metaData = try metaDataProvider.getMetaData()
        let realtimeToken: String = metaData.realtimeToken
        let customerID: String? = storage[.customerID]
        let visitorID: String? = context.type == .setUserID ? storage[.initialVisitorId] : storage[.visitorID]

        if (customerID ?? visitorID) == nil {
            throw RealTimeError.eitherCustomerOrVisitorIdIsNil
        }

        return RealtimeEvent(
            tid: realtimeToken,
            cid: customerID,
            visitorId: visitorID,
            eid: String(context.config.id),
            context: context.event.parameters,
            firstVisitorDate: storage[.firstVisitTimestamp] ?? 0
        )
    }

}
