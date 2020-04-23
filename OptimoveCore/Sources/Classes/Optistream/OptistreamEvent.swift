//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

public struct OptistreamEvent: Codable {
    public let uuid: String
    public let tenant: Int
    public let category: String
    public let event: String
    public let origin: String
    public let customer: String?
    public let visitor: String
    public let timestamp: Int
    public let context: JSON

    public init(
        uuid: String,
        tenant: Int,
        category: String,
        event: String,
        origin: String,
        customer: String?,
        visitor: String,
        timestamp: Int,
        context: JSON
    ) {
        self.uuid = uuid
        self.tenant = tenant
        self.category = category
        self.event = event
        self.origin = origin
        self.customer = customer
        self.visitor = visitor
        self.timestamp = timestamp
        self.context = context
    }
}

extension OptistreamEvent: Equatable {

    public static func == (lhs: OptistreamEvent, rhs: OptistreamEvent) -> Bool {
        return lhs.uuid == rhs.uuid
    }

}
