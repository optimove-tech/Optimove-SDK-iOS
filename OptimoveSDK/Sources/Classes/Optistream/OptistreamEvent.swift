//  Copyright © 2020 Optimove. All rights reserved.

import Foundation
import GenericJSON
import OptimoveCore

struct OptistreamEvent: Codable {
    let tenant: Int
    let category: String
    let event: String
    let origin: String
    let customer: String?
    let visitor: String
    let timestamp: String
    let context: JSON
    var metadata: Metadata

    struct Metadata: Codable, Hashable {
        var realtime: Bool
        var firstVisitorDate: Int64?
        let eventId: String
        let requestId: String
        let platform: String = "ios"
        let version: String = SDKVersion

        enum CodingKeys: String, CodingKey {
            case realtime
            case firstVisitorDate
            case eventId
            case requestId
            case platform = "sdk_platform"
            case version = "sdk_version"
        }

        init(
            realtime: Bool,
            firstVisitorDate: Int64?,
            eventId: String,
            requestId: String
        ) {
            self.realtime = realtime
            self.firstVisitorDate = firstVisitorDate
            self.eventId = eventId
            self.requestId = requestId
        }
    }

    init(
        tenant: Int,
        category: String,
        event: String,
        origin: String,
        customer: String?,
        visitor: String,
        timestamp: String,
        context: JSON,
        metadata: Metadata
    ) {
        self.tenant = tenant
        self.category = category
        self.event = event
        self.origin = origin
        self.customer = customer
        self.visitor = visitor
        self.timestamp = timestamp
        self.context = context
        self.metadata = metadata
    }
}

extension OptistreamEvent: Equatable {
    static func == (lhs: OptistreamEvent, rhs: OptistreamEvent) -> Bool {
        return lhs.metadata.eventId == rhs.metadata.eventId
    }
}

extension OptistreamEvent: Hashable {}
