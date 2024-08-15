import Foundation

public struct Preferences: Codable {
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

        public init(id: String, name: String, description: String, subscribedChannels: [Channel]) {
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

    public let customerPreferences: [Topic]
    public let configuredChannels: [Channel]

    public init(topics: [Topic], configuredChannels: [Channel]) {
        self.customerPreferences = topics
        self.configuredChannels = configuredChannels
    }

    enum CodingKeys: String, CodingKey {
        case customerPreferences = "topics"
        case configuredChannels = "channels"
    }
}
