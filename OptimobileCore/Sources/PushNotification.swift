//  Copyright © 2023 Optimove. All rights reserved.

import Foundation

/// Represents a push notification received from the server.
public struct PushNotification: Decodable {
    public struct Data: Decodable {
        public let id: Int

        private enum CodingKeys: String, CodingKey {
            case id
            case data
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
            self.id = try data.decode(Int.self, forKey: CodingKeys.id)
        }
    }

    public struct Button: Decodable {
        public struct Icon: Decodable {
            public enum IconType: String, Decodable {
                case custom
                case system
            }

            public let id: String
            public let type: IconType
        }

        public let id: String
        public let icon: Icon?
        public let text: String
    }

    public let id: Int
    public let deeplink: PushNotification.Data?
    public let badge: Int?
    public let buttons: [Button]?
    public let isBackground: Bool
    public let picturePath: String?
    public let url: URL?

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
        case u
    }

    public init(userInfo: [AnyHashable: Any]) throws {
        let data = try JSONSerialization.data(withJSONObject: userInfo)
        let decoder = JSONDecoder()
        self = try decoder.decode(PushNotification.self, from: data)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let custom = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .custom)
        self.badge = try custom.decodeIfPresent(Int.self, forKey: .badge)

        let a = try custom.nestedContainer(keyedBy: CodingKeys.self, forKey: .a)
        self.buttons = try a.decodeIfPresent([Button].self, forKey: .buttons)

        let message = try a.nestedContainer(keyedBy: CodingKeys.self, forKey: .message)
        let messageData = try message.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        self.id = try messageData.decode(Int.self, forKey: .id)

        let aps = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .aps)
        let isBackground = try aps.decodeIfPresent(Int.self, forKey: .isBackground)
        self.isBackground = isBackground == 1 ? true : false

        let attachments = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .attachments)
        self.picturePath = try attachments?.decodeIfPresent(String.self, forKey: .pictureUrl)

        self.url = try custom.decodeIfPresent(URL.self, forKey: .u)

        self.deeplink = try a.decodeIfPresent(PushNotification.Data.self, forKey: .deeplink)
    }
}
