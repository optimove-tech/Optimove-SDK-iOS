import Foundation

public class Topic: NSObject, Codable {
    private(set) var topicId: String
    private(set) var topicName: String
    private(set) var topicDescription: String
    private(set) var channelSubscription: [Channel]

    public init(id: String, name: String, description: String, subscribedChannels: [Channel]) {
        topicId = id
        topicName = name
        topicDescription = description
        channelSubscription = subscribedChannels
    }
}
