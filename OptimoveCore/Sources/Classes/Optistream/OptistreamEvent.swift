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

        public struct Channel: Codable, Hashable {

            public let airship: OptimoveAirshipIntegration.Airship?

            public init(airship: OptimoveAirshipIntegration.Airship?) {
                self.airship = airship
            }
        }

        public let channel: Channel?
        public var realtime: Bool
        public var firstVisitorDate: Int64?
        public let eventId: String
        public let requestId: String
        public let platform: String = "ios"
        public let version: String = SDKVersion
        public let validations: [ValidationIssue]

        enum CodingKeys: String, CodingKey {
            case channel
            case realtime
            case firstVisitorDate
            case eventId
            case requestId
            case platform = "sdk_platform"
            case version = "sdk_version"
            case validations
        }

        public init(
            channel: OptistreamEvent.Metadata.Channel?,
            realtime: Bool,
            firstVisitorDate: Int64?,
            eventId: String,
            requestId: String,
            validations: [ValidationIssue]
        ) {
            self.channel = channel
            self.realtime = realtime
            self.firstVisitorDate = firstVisitorDate
            self.eventId = eventId
            self.requestId = requestId
            self.validations = validations
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
