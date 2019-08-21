// Copiright 2019 Optimove

import Foundation

// MARK: - NotificationPayload

struct NotificationPayload: Decodable {
    let title: String
    let content: String
    let dynamicLinks: DynamicLinks?
    let deepLinkPersonalization: DeeplinkPersonalization?
    let campaignDetails: CampaignDetails?
    let collapseKey: String?
    let isOptipush: Bool
    let media: MediaAttachment?
    let userAction: UserAction?
    
    enum CodingKeys: String, CodingKey {
        case title
        case content
        case dynamicLinks = "dynamic_links"
        case deepLinkPersonalization = "deep_link_personalization_values"
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.content = try container.decode(String.self, forKey: .content)
        self.dynamicLinks = try DynamicLinks(firebaseFrom: decoder)
        self.deepLinkPersonalization = try? DeeplinkPersonalization(firebaseFrom: decoder)
        self.campaignDetails = try? CampaignDetails(firebaseFrom: decoder)
        self.collapseKey = try container.decodeIfPresent(String.self, forKey: .collapseKey)
        self.isOptipush = try container.decode(StringCodableMap<Bool>.self, forKey: .isOptipush).decoded
        self.media = try? MediaAttachment(firebaseFrom: decoder)
        self.userAction = try? UserAction(firebaseFrom: decoder)
    }
}

// MARK: - Campaing details

struct CampaignDetails: Decodable {
    let campaignId: Int
    let actionSerial: Int
    let templateId: Int
    let engagementId: Int
    let campaignType: Int

    /// The custom decoder does preprocess before the primary decoder.
    init(firebaseFrom decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NotificationPayload.CodingKeys.self)
        self.campaignId = try container.decode(StringCodableMap<Int>.self, forKey: .campaignID).decoded
        self.actionSerial = try container.decode(StringCodableMap<Int>.self, forKey: .actionSerial).decoded
        self.templateId = try container.decode(StringCodableMap<Int>.self, forKey: .templateID).decoded
        self.engagementId = try container.decode(StringCodableMap<Int>.self, forKey: .engagementID).decoded
        self.campaignType = try container.decode(StringCodableMap<Int>.self, forKey: .campaignType).decoded
    }
}
struct DeeplinkPersonalization: Decodable {
    let values: [String: String]

    /// The custom decoder does preprocess before the primary decoder.
    init(firebaseFrom decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NotificationPayload.CodingKeys.self)
        let string = try container.decode(String.self, forKey: .deepLinkPersonalization)
        let data: Data = try cast(string.data(using: .utf8))
        values = try JSONDecoder().decode([String: String].self, from: data)
    }
}


// MARK: - Dynamic links

struct DynamicLinks: Decodable {
    let ios: [String: URL]?

    /// The custom decoder does preprocess before the primary decoder.
    init(firebaseFrom decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NotificationPayload.CodingKeys.self)
        let string = try container.decode(String.self, forKey: .dynamicLinks)
        let data: Data = try cast(string.data(using: .utf8))
        self = try JSONDecoder().decode(DynamicLinks.self, from: data)
    }
}


// MARK: - Media

struct MediaAttachment: Decodable {
    let url: URL
    let mediaType: MediaType
    
    enum MediaType: String, Codable {
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

struct UserAction: Decodable {
    let categoryIdentifier: String
    let actions: [Action]
    
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

struct Action: Decodable {
    let identifier: String
    let title: String
    let deeplink: String?
}

/// https://stackoverflow.com/a/44596291
struct StringCodableMap<Decoded: LosslessStringConvertible> : Codable {

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
