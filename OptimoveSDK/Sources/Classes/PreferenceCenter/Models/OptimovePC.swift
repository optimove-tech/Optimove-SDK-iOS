import Foundation

public struct OptimovePC {
    public enum Channel: Int, Codable {
        case mobilePush = 489
        case webPush = 490
        case sms = 493
        case inApp = 427
        case whatsapp = 498
        case mail = 15
        case inbox = 495
    }

    public struct Topic: Codable {
        public let id: String
        public let name: String
        public let description: String
        public let subscribedChannels: [Channel]

        init(id: String, name: String, description: String, subscribedChannels: [Channel]) {
            self.id = id
            self.name = name
            self.description = description
            self.subscribedChannels = subscribedChannels
        }

        enum CodingKeys: String, CodingKey {
            case id = "topicId"
            case name = "topicName"
            case description = "topicDescription"
            case subscribedChannels = "channelSubscription"
        }
    }

    public struct Preferences: Codable {
        public let customerPreferences: [Topic]
        public let configuredChannels: [Channel]

        init(customerPreferences: [Topic], configuredChannels: [Channel]) {
            self.customerPreferences = customerPreferences
            self.configuredChannels = configuredChannels
        }

        enum CodingKeys: String, CodingKey {
            case customerPreferences = "topics"
            case configuredChannels = "channels"
        }
    }

    public struct PreferenceUpdate: Codable {
        public let topicId: String
        public let subscribedChannels: [Channel]

        public init(topicId: String, subscribedChannels: [Channel]) {
            self.topicId = topicId
            self.subscribedChannels = subscribedChannels
        }

        enum CodingKeys: String, CodingKey {
            case topicId = "topicId"
            case subscribedChannels = "channelSubscription"
        }
    }
}


