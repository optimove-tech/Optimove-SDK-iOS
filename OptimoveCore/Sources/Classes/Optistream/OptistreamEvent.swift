//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

public struct OptistreamEvent: Codable {
    public let tenant: Int
    public let category: String
    public let event: String
    public let origin: String
    public let customer: String?
    public let visitor: String
    public let timestamp: String
    public let context: JSON
    public var metadata: Metadata

    public struct Metadata: Codable, Hashable {

        public var realtime: Bool
        public var firstVisitorDate: Int64?
        public let eventId: String
        public let requestId: String
        public let platform: String = "ios"
        public let version: String = SDKVersion

        enum CodingKeys: String, CodingKey {
            case realtime
            case firstVisitorDate
            case eventId
            case requestId
            case platform = "sdk_platform"
            case version = "sdk_version"
        }

        public init(
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

    public init(
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

    public static func == (lhs: OptistreamEvent, rhs: OptistreamEvent) -> Bool {
        return lhs.metadata.eventId == rhs.metadata.eventId
    }

}

extension OptistreamEvent: Hashable { }
