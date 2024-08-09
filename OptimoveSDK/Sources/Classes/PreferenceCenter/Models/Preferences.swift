import Foundation

public struct Preferences: Codable {
    public struct Topic: Codable {
        public let topicId: String
        public let topicName: String
        public let topicDescription: String
        public let channelSubscription: [Channel]

        public init(topicId: String, topicName: String, topicDescription: String, channelSubscription: [Channel]) {
            self.topicId = topicId
            self.topicName = topicName
            self.topicDescription = topicDescription
            self.channelSubscription = channelSubscription
        }
    }

    public let topics: [Topic]
    public let channels: [Channel]

    public init(topics: [Topic], channels: [Channel]) {
        self.topics = topics
        self.channels = channels
    }
}
