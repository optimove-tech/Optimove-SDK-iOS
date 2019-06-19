import Foundation

class SetUserId: OptimoveCoreEvent {
    let originalVisitorId: String
    let userId: String
    let updatedVisitorId: String

    var name: String {
        return OptimoveKeys.Configuration.setUserId.rawValue
    }
    var parameters: [String: Any]

    init(originalVistorId: String, userId: String, updateVisitorId: String) {
        self.originalVisitorId = originalVistorId
        self.userId = userId
        self.updatedVisitorId = updateVisitorId

        guard CustomerID != nil else {
            OptiLoggerMessages.logCustomerIdNilError()
            self.parameters = [:]
            return
        }

        self.parameters = [
            OptimoveKeys.Configuration.originalVisitorId.rawValue: originalVistorId as Any,
            OptimoveKeys.Configuration.realtimeUserId.rawValue: userId as Any,
            "updatedVisitorId": updatedVisitorId
        ]

    }
}
