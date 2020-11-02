//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

// MARK: - NotificationPayload

public struct NotificationPayload: Decodable {
    public let title: String?
    public let content: String
    public let deepLink: URL?
    public let campaign: NotificationCampaignContainer?
    public let isOptipush: Bool
    public let media: MediaAttachment?
    public let eventVariables: EventVariables

    enum CodingKeys: String, CodingKey {
        case title
        case content
        case deepLink = "dl"
        case campaign
        case isOptipush = "is_optipush"
        case media
        case userAction = "user_action"
        case eventVariables = "ev"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.campaign = try? NotificationCampaignContainer(firebaseFrom: decoder)
        self.media = try? MediaAttachment(firebaseFrom: decoder)
        self.deepLink = try? DeepLink(firebaseFrom: decoder).url
        self.content = try container.decode(String.self, forKey: .content)
        self.isOptipush = try container.decode(StringCodableMap<Bool>.self, forKey: .isOptipush).decoded
        self.eventVariables = try container.decode(EventVariables.self, forKey: .eventVariables)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
    }
}

// MARK: - Notification campaign

public enum NotificationCampaignType: String, CodingKey, CaseIterable {
    case scheduled = "scheduled_campaign"
    case triggered = "triggered_campaign"
}

public struct NotificationCampaignContainer {
    public let type: NotificationCampaignType
    public let identityToken: String

    init(firebaseFrom decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NotificationCampaignType.self)
        let decoded: (identityToken: String, type: NotificationCampaignType) = try {
            if let string = try container.decodeIfPresent(String.self, forKey: .scheduled) {
                return (identityToken: string, type: .scheduled)
            }
            if let string = try container.decodeIfPresent(String.self, forKey: .triggered) {
                return (identityToken: string, type: .triggered)
            }
            throw DecodingError.valueNotFound(
                NotificationCampaignContainer.self,
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription:
                    """
                    Unable to find a supported Notification campaign type.
                    Probably this is a test push.
                    Supported types: \(NotificationCampaignType.allCases.map { $0.rawValue })
                    """
                )
            )
        }()
        self.type = decoded.type
        self.identityToken = decoded.identityToken
    }

}

// MARK: - Deep link

public struct DeepLink: Decodable {

    public let url: URL?

    init(firebaseFrom decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NotificationPayload.CodingKeys.self)
        guard let string = try container.decodeIfPresent(String.self, forKey: .deepLink) else {
            throw GuardError.custom("Not found value for key \(NotificationPayload.CodingKeys.deepLink.rawValue)")
        }
        let data: Data = try cast(string.data(using: .utf8))
        self.url = URL(dataRepresentation: data, relativeTo: nil)
    }
}

// MARK: - Media

public struct MediaAttachment: Decodable {
    public let url: URL
    public let mediaType: MediaType

    public enum MediaType: String, Codable {
        case image
        case video
        case gif
    }

    enum CodingKeys: String, CodingKey {
        case url
        case mediaType = "media_type"
    }

    /// The custom decoder does preprocess before the primary decoder.
    init(firebaseFrom decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NotificationPayload.CodingKeys.self)
        let string = try container.decode(String.self, forKey: .media)
        let data: Data = try cast(string.data(using: .utf8))
        self = try JSONDecoder().decode(MediaAttachment.self, from: data)
    }

}

public struct EventVariables: Decodable {
    public let tenant: Int
    public let customer: String?
    public let visitor: String
    public let firstRunTimestamp: Int64
    public let optitrackEndpoint: URL
    public let requestId: String

    enum CodingKeys: String, CodingKey {
        case tenant = "t"
        case customer = "c"
        case visitor = "v"
        case firstRunTimestamp = "frt"
        case optitrackEndpoint = "oe"
        case requestId = "rid"
    }
}

/// https://stackoverflow.com/a/44596291
struct StringCodableMap<Decoded: LosslessStringConvertible>: Codable {

var decoded: Decoded

    init(_ decoded: Decoded) {
        self.decoded = decoded
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        let decodedString = try container.decode(String.self)

        guard let decoded = Decoded(decodedString) else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: """
                The string \(decodedString) is not representable as a \(Decoded.self)
                """
            )
        }

        self.decoded = decoded
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(decoded.description)
    }
}
