import Foundation

public struct PreferenceUpdateRequest: Codable {
    public let topicId: String
    public let channelSubscription: [Channel]

    public init(topicId: String, channelSubscription: [Channel]) {
        self.topicId = topicId
        self.channelSubscription = channelSubscription
    }
}
