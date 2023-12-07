//  Copyright © 2023 Optimove. All rights reserved.

/// Represents a push notification received from the server.
struct PushNotification: Decodable {
    struct Button: Decodable {
        struct Icon: Decodable {
            enum IconType: String, Decodable {
                case custom
                case system
            }

            let id: String
            let type: IconType
        }

        let id: String
        let icon: Icon?
        let text: String
    }

    let id: Int
    let badge: Int?
    let buttons: [Button]?
    let isBackground: Bool
    let picturePath: String?

    private enum CodingKeys: String, CodingKey {
        case a
        case aps
        case attachments
        case badge = "badge_inc"
        case buttons = "k.buttons"
        case custom
        case data
        case deeplink = "k.deepLink"
        case id
        case isBackground = "content-available"
        case message = "k.message"
        case pictureUrl
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let custom = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .custom)
        self.badge = try custom.decodeIfPresent(Int.self, forKey: .badge)

        let a = try custom.nestedContainer(keyedBy: CodingKeys.self, forKey: .a)
        self.buttons = try a.decodeIfPresent([Button].self, forKey: .buttons)

        let message = try a.nestedContainer(keyedBy: CodingKeys.self, forKey: .message)
        let data = try message.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        self.id = try data.decode(Int.self, forKey: .id)

        let aps = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .aps)
        let isBackground = try aps.decodeIfPresent(Int.self, forKey: .isBackground)
        self.isBackground = isBackground == 1 ? true : false

        let attachments = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .attachments)
        self.picturePath = try attachments?.decodeIfPresent(String.self, forKey: .pictureUrl)
    }
}
