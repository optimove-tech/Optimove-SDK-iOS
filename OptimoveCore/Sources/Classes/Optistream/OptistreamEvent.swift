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
    public let timestamp: String // iso8601
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

        public init(
            channel: OptistreamEvent.Metadata.Channel?,
            realtime: Bool
        ) {
            self.channel = channel
            self.realtime = realtime
        }

    }

    public init(
        uuid: String,
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
        self.uuid = uuid
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
        return lhs.uuid == rhs.uuid
    }

}

extension OptistreamEvent: Hashable { }
