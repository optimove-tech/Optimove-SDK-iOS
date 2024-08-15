import Foundation

@available(iOS 13.0, *)
public struct PreferenceUpdate: Codable {
    public let topicId: String
    public let subscribedChannels: [Preferences.Channel]

    enum CodingKeys: String, CodingKey {
        case topicId = "topicId"
        case subscribedChannels = "channelSubscription"
    }

    public init(topicId: String, subscribedChannels: [Preferences.Channel]) {
        self.topicId = topicId
        self.subscribedChannels = subscribedChannels
    }
}
