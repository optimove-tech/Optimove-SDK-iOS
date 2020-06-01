//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

// MARK: - NotificationPayload

public struct NotificationPayload: Decodable {
    public let title: String?
    public let content: String
    public let dynamicLinks: DynamicLinks?
    public let deepLinkPersonalization: DeeplinkPersonalization?
    public let campaign: NotificationCampaignContainer?
    public let isOptipush: Bool
    public let media: MediaAttachment?

    enum CodingKeys: String, CodingKey {
        case title
        case content
        case dynamicLinks = "dynamic_links"
        case deepLinkPersonalization = "deep_link_personalization_values"
        case campaign
        case isOptipush = "is_optipush"
        case media
        case userAction = "user_action"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.content = try container.decode(String.self, forKey: .content)
        self.dynamicLinks = try? DynamicLinks(firebaseFrom: decoder)
        self.deepLinkPersonalization = try? DeeplinkPersonalization(firebaseFrom: decoder)
        self.campaign = try? NotificationCampaignContainer(firebaseFrom: decoder)
        self.isOptipush = try container.decode(StringCodableMap<Bool>.self, forKey: .isOptipush).decoded
        self.media = try? MediaAttachment(firebaseFrom: decoder)
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

public struct DeeplinkPersonalization: Decodable {
    public let values: [String: String]

    /// The custom decoder does preprocess before the primary decoder.
    init(firebaseFrom decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NotificationPayload.CodingKeys.self)
        let string = try container.decode(String.self, forKey: .deepLinkPersonalization)
        let data: Data = try cast(string.data(using: .utf8))
        values = try JSONDecoder().decode([String: String].self, from: data)
    }
}

// MARK: - Dynamic links

public struct DynamicLinks: Decodable {
    public let ios: [String: URL]?

    /// The custom decoder does preprocess before the primary decoder.
    init(firebaseFrom decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NotificationPayload.CodingKeys.self)
        guard let string = try container.decodeIfPresent(String.self, forKey: .dynamicLinks) else {
            throw GuardError.custom("Not found value for key \(NotificationPayload.CodingKeys.dynamicLinks.rawValue)")
        }
        let data: Data = try cast(string.data(using: .utf8))
        self = try JSONDecoder().decode(DynamicLinks.self, from: data)
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
