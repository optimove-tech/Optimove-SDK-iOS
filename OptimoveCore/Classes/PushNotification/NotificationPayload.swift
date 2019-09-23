//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

// MARK: - NotificationPayload

public struct NotificationPayload: Decodable {
    public let title: String
    public let content: String
    public let dynamicLinks: DynamicLinks?
    public let deepLinkPersonalization: DeeplinkPersonalization?
    public let campaign: NotificationCampaign?
    public let collapseKey: String?
    public let isOptipush: Bool
    public let media: MediaAttachment?
    public let userAction: UserAction?

    enum CodingKeys: String, CodingKey {
        case title
        case content
        case dynamicLinks = "dynamic_links"
        case deepLinkPersonalization = "deep_link_personalization_values"
        case campaign
        case campaignID = "campaign_id"
        case actionSerial = "action_serial"
        case templateID = "template_id"
        case engagementID = "engagement_id"
        case campaignType = "campaign_type"
        case collapseKey = "collapse_Key"
        case isOptipush = "is_optipush"
        case media
        case userAction = "user_action"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.content = try container.decode(String.self, forKey: .content)
        self.dynamicLinks = try? DynamicLinks(firebaseFrom: decoder)
        self.deepLinkPersonalization = try? DeeplinkPersonalization(firebaseFrom: decoder)
        self.campaign = try? NotificationCampaignContainer(firebaseFrom: decoder).campaign
        self.collapseKey = try container.decodeIfPresent(String.self, forKey: .collapseKey)
        self.isOptipush = try container.decode(StringCodableMap<Bool>.self, forKey: .isOptipush).decoded
        self.media = try? MediaAttachment(firebaseFrom: decoder)
        self.userAction = try? UserAction(firebaseFrom: decoder)
    }
}

// MARK: - Notification campaign

public enum NotificationCampaignType: String, CodingKey, CaseIterable {
    case scheduled = "scheduled_campaign"
    case triggered = "triggered_campaign"
}

public protocol NotificationCampaign: Decodable {
    var type: NotificationCampaignType { get }
}

struct NotificationCampaignContainer {
    let campaign: NotificationCampaign

    init(firebaseFrom decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NotificationCampaignType.self)
        let stringAndCampaignType: (string: String, type: NotificationCampaignType) = try {
            if let string = try container.decodeIfPresent(String.self, forKey: .scheduled) {
                return (string, .scheduled)
            }
            if let string = try container.decodeIfPresent(String.self, forKey: .triggered) {
                return (string, .triggered)
            }
            throw DecodingError.valueNotFound(
                NotificationCampaign.self,
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription:
                    """
                    Unable to find a supported Notification campaign type.
                    Supported types: \(NotificationCampaignType.allCases.map { $0.rawValue })
                    """
                )
            )
        }()
        let data: Data = try cast(stringAndCampaignType.string.data(using: .utf8))
        switch stringAndCampaignType.type {
        case .scheduled:
            self.campaign = try JSONDecoder().decode(ScheduledNotificationCampaign.self, from: data)
        case .triggered:
            self.campaign = try JSONDecoder().decode(TriggeredNotificationCampaign.self, from: data)
        }
    }

}

public struct TriggeredNotificationCampaign: NotificationCampaign {
    public private(set) var type: NotificationCampaignType = .triggered
    public let actionSerial: Int
    public let actionID: Int
    public let templateID: Int

    public init(
        actionSerial: Int,
        actionID: Int,
        templateID: Int
    ) {
        self.actionSerial = actionSerial
        self.actionID = actionID
        self.templateID = templateID
    }

    enum CodingKeys: String, CodingKey {
        case actionSerial = "action_serial"
        case actionID = "action_id"
        case templateID = "template_id"
    }

    /// The custom decoder does preprocess before the primary decoder.
    init(firebaseFrom decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NotificationPayload.CodingKeys.self)
        let string = try container.decode(String.self, forKey: .campaign)
        let data: Data = try cast(string.data(using: .utf8))
        self = try JSONDecoder().decode(TriggeredNotificationCampaign.self, from: data)
    }
}

public struct ScheduledNotificationCampaign: NotificationCampaign {
    public private(set) var type: NotificationCampaignType = .scheduled
    public let campaignID: Int
    public let actionSerial: Int
    public let templateID: Int
    public let engagementID: Int
    public let campaignType: Int

    public init(
        campaignID: Int,
        actionSerial: Int,
        templateID: Int,
        engagementID: Int,
        campaignType: Int
    ) {
        self.campaignID = campaignID
        self.actionSerial = actionSerial
        self.templateID = templateID
        self.engagementID = engagementID
        self.campaignType = campaignType
    }

    enum CodingKeys: String, CodingKey {
        case campaignID = "campaign_id"
        case actionSerial = "action_serial"
        case templateID = "template_id"
        case engagementID = "engagement_id"
        case campaignType = "campaign_type"
    }

    /// The custom decoder does preprocess before the primary decoder.
    init(firebaseFrom decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NotificationPayload.CodingKeys.self)
        let string = try container.decode(String.self, forKey: .campaign)
        let data: Data = try cast(string.data(using: .utf8))
        self = try JSONDecoder().decode(ScheduledNotificationCampaign.self, from: data)
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
        let string = try container.decode(String.self, forKey: .dynamicLinks)
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

// MARK: - UserAction

public struct UserAction: Decodable {
    public let categoryIdentifier: String
    public let actions: [Action]

    enum CodingKeys: String, CodingKey {
        case categoryIdentifier = "category_identifier"
        case actions = "actions"
    }

    /// The custom decoder does preprocess before the primary decoder.
    init(firebaseFrom decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NotificationPayload.CodingKeys.self)
        let string = try container.decode(String.self, forKey: .userAction)
        let data: Data = try cast(string.data(using: .utf8))
        self = try JSONDecoder().decode(UserAction.self, from: data)
    }
}

// MARK: - Action

public struct Action: Decodable {
    public let identifier: String
    public let title: String
    public let deeplink: String?
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
