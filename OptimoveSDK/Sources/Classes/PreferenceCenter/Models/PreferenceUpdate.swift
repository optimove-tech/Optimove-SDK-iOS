import Foundation

public struct PreferenceUpdate: Codable {
    public let topicId: String
    public let subscribedChannels: [Channel]

    enum CodingKeys: String, CodingKey {
        case topicId = "topicId"
        case subscribedChannels = "channelSubscription"
    }

    public init(topicId: String, subscribedChannels: [Channel]) {
        self.topicId = topicId
        self.subscribedChannels = subscribedChannels
    }
}
