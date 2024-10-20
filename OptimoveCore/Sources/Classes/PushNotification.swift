//  Copyright © 2023 Optimove. All rights reserved.

import Foundation

/// Represents a push notification received from the server.
public struct PushNotification: Decodable {
    public struct Aps: Decodable {
        public struct Alert: Decodable {
            public let title: String?
            public let body: String?
        }

        public let alert: Alert?
        public let badge: Int?
        public let sound: String?
        /// The background notification flag. To perform a silent background update, specify the value 1 and don’t include the alert, badge, or sound keys in your payload. If this key is present with a value of 1, the system attempts to initialize your app in the background so that it can make updates to its user interface. If the app is already running in the foreground, this key has no effect.
        public let isBackground: Bool
        /// The notification service app extension flag. If the value is 1, the system passes the notification to your notification service app extension before delivery. Use your extension to modify the notification’s content.
        public let isExtension: Bool

        private enum CodingKeys: String, CodingKey {
            case alert
            case badge
            case sound
            case isBackground = "content-available"
            case isExtension = "mutable-content"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.alert = try container.decodeIfPresent(Alert.self, forKey: .alert)
            self.badge = try container.decodeIfPresent(Int.self, forKey: .badge)
            self.sound = try container.decodeIfPresent(String.self, forKey: .sound)
            let isBackground = try container.decodeIfPresent(Int.self, forKey: .isBackground)
            self.isBackground = isBackground == 1
            let isExtension = try container.decodeIfPresent(Int.self, forKey: .isExtension)
            self.isExtension = isExtension == 1
        }
    }

    public struct Attachment: Decodable {
        public let pictureUrl: String?
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

    public let aps: Aps
    public let attachment: PushNotification.Attachment?
    /// Optimove badge
    public let badgeIncrement: Int?
    public let buttons: [PushNotification.Button]?
    public let deeplink: PushNotification.Data?
    public let message: PushNotification.Data
    public let url: URL?

    private enum CodingKeys: String, CodingKey {
        case a
        case aps
        case attachments
        case badgeIncrement = "badge_inc"
        case buttons = "k.buttons"
        case custom
        case deeplink = "k.deepLink"
        case message = "k.message"
        case u
    }

    public init(userInfo: [AnyHashable: Any]) throws {
        let data = try JSONSerialization.data(withJSONObject: userInfo)
        let decoder = JSONDecoder()
        self = try decoder.decode(PushNotification.self, from: data)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.aps = try container.decode(Aps.self, forKey: .aps)
        self.attachment = try container.decodeIfPresent(Attachment.self, forKey: .attachments)

        let custom = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .custom)
        self.badgeIncrement = try custom.decodeIfPresent(Int.self, forKey: .badgeIncrement)
        self.url = try custom.decodeIfPresent(URL.self, forKey: .u)

        let a = try custom.nestedContainer(keyedBy: CodingKeys.self, forKey: .a)
        self.buttons = try a.decodeIfPresent([Button].self, forKey: .buttons)
        self.deeplink = try a.decodeIfPresent(PushNotification.Data.self, forKey: .deeplink)
        self.message = try a.decode(PushNotification.Data.self, forKey: .message)
    }
}
