//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

public struct OptistreamEvent: Codable {
    public let tenant: Int
    public let category: String
    public let event: String
    public let origin: String
    public let customer: String?
    public let visitor: String
    public let timestamp: Date
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
        public let uuid: UUID

        public init(
            channel: OptistreamEvent.Metadata.Channel?,
            realtime: Bool,
            uuid: UUID
        ) {
            self.channel = channel
            self.realtime = realtime
            self.uuid = uuid
        }

    }

    public init(
        tenant: Int,
        category: String,
        event: String,
        origin: String,
        customer: String?,
        visitor: String,
        timestamp: Date,
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
        return lhs.metadata.uuid == rhs.metadata.uuid
    }

}

extension OptistreamEvent: Hashable { }
