// Copiright 2019 Optimove

import Foundation

class BaseMbaasModel: Codable, Equatable {

    let tenantId: Int
    let operation: MbaasOperation
    let userIdPayload: UserIdPayload

    init(operation: MbaasOperation,
         tenantId: Int,
         userIdPayload: BaseMbaasModel.UserIdPayload) {
        self.operation = operation
        self.tenantId = tenantId
        self.userIdPayload = userIdPayload
    }

    required init(from decoder: Decoder) throws {
        fatalError("Use successor's init(from:).")
    }

    func encode(to encoder: Encoder) throws {
        fatalError("Use successor's  encode(to:).")
    }

    static func == (lhs: BaseMbaasModel, rhs: BaseMbaasModel) -> Bool {
        return lhs.operation == rhs.operation && lhs.tenantId == rhs.tenantId && lhs.userIdPayload == rhs.userIdPayload
    }

}

extension BaseMbaasModel {

    enum UserIdPayload {

        case visitorID(String)
        case customerID(CustomerIdPayload)

        struct CustomerIdPayload: Equatable {
            let customerID: String
            let isConversion: Bool?
            let initialVisitorId: String?
        }
    }
}

extension BaseMbaasModel.UserIdPayload: Equatable {

    static func == (lhs: BaseMbaasModel.UserIdPayload, rhs: BaseMbaasModel.UserIdPayload) -> Bool {
        switch (lhs, rhs) {
        case let (.visitorID(lid), .visitorID(rid)):
            return lid == rid
        case let (.customerID(lpayload), .customerID(rpayload)):
            return lpayload == rpayload
        default:
            return false
        }
    }

}

extension BaseMbaasModel.UserIdPayload {

    init(from container: KeyedDecodingContainer<OptimoveKeys.Registration>) throws {
        // Case for customer
        if container.contains(.customerID) {
            self = .customerID(
                BaseMbaasModel.UserIdPayload.CustomerIdPayload(
                    customerID: try container.decode(String.self, forKey: .customerID),
                    isConversion: try container.decodeIfPresent(Bool.self, forKey: .isConversion),
                    initialVisitorId: try container.decodeIfPresent(String.self, forKey: .origVisitorID)
                )
            )
        }
        // Case for visitor
        else {
            self = .visitorID(try container.decode(String.self, forKey: .visitorID))
        }
    }

    func encode(to container: inout KeyedEncodingContainer<OptimoveKeys.Registration>) throws {
        switch self {
        case let .visitorID(visitorID):
            try container.encode(visitorID, forKey: .visitorID)
        case let .customerID(payload):
            try container.encode(payload.customerID, forKey: .customerID)
            try container.encodeIfPresent(payload.isConversion, forKey: .isConversion)
            try container.encodeIfPresent(payload.initialVisitorId, forKey: .origVisitorID)
        }
    }

}
