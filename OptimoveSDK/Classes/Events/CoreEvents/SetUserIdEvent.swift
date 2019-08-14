// Copiright 2019 Optimove

final class SetUserIdEvent: OptimoveCoreEvent {

    struct Constants {
        static let name = OptimoveKeys.Configuration.setUserId.rawValue
        struct Key {
            static let originalVistorId = OptimoveKeys.Configuration.originalVisitorId.rawValue
            static let userId = OptimoveKeys.Configuration.realtimeUserId.rawValue
            static let updatedVisitorId = OptimoveKeys.Configuration.realtimeupdatedVisitorId.rawValue
        }
    }
    
    let name: String = Constants.name
    let parameters: [String: Any]

    init(originalVistorId: String, userId: String, updateVisitorId: String) {
        parameters = [
            Constants.Key.originalVistorId: originalVistorId,
            Constants.Key.userId: userId,
            Constants.Key.updatedVisitorId: updateVisitorId
        ]
    }
}
