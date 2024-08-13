import Foundation

public struct Preferences: Codable {
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

    public let topics: [Topic]
    public let configuredChannels: [Channel]

    public init(topics: [Topic], configuredChannels: [Channel]) {
        self.topics = topics
        self.configuredChannels = configuredChannels
    }

    enum CodingKeys: String, CodingKey {
        case topics = "topics"
        case configuredChannels = "channels"
    }
}
