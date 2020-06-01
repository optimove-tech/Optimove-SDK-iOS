//  Copyright © 2019 Optimove. All rights reserved.

final class SetUserIdEvent: Event {

    struct Constants {
        static let name = OptimoveKeys.Configuration.setUserId.rawValue
        struct Key {
            static let originalVistorId = OptimoveKeys.Configuration.originalVisitorId.rawValue
            static let userId = OptimoveKeys.Configuration.realtimeUserId.rawValue
            static let updatedVisitorId = OptimoveKeys.Configuration.realtimeupdatedVisitorId.rawValue
        }
    }

    init(originalVistorId: String, userId: String, updateVisitorId: String) {
        super.init(
            name: Constants.name,
            context: [
                Constants.Key.originalVistorId: originalVistorId,
                Constants.Key.userId: userId,
                Constants.Key.updatedVisitorId: updateVisitorId
            ]
        )
    }
}
