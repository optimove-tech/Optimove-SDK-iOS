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
    public let metadata: Metadata

    public struct Metadata: Codable {

        public struct Channel: Codable {
            public let airship: OptimoveAirshipIntegration.Airship?
        }

        let platform: String
        let version: String
        let appVersion: String
        let osVersion: String
        let deviceModel: String
        let channel: Channel?
        let realtime: Bool?

        enum CodingKeys: String, CodingKey {
            case platform = "sdk_platform"
            case version = "sdk_version"
            case appVersion = "app_version"
            case osVersion = "os_version"
            case deviceModel = "device_model"
            case channel
            case realtime
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
