import Foundation

public class Topic: NSObject, Codable {
    public var topicId: String
    var topicName: String
    var topicDescription: String
    var channelSubscription: [Channel]

    public func getId() -> String {
        return topicId
    }

    public func getName() -> String {
        return topicName
    }

    public func getDescription() -> String {
        return topicDescription
    }

    public func getSubscribedChannels() -> [Channel] {
        return channelSubscription
    }

    public init(id: String, name: String, description: String, subscribedChannels: [Channel]) {
        topicId = id
        topicName = name
        topicDescription = description
        channelSubscription = subscribedChannels
    }

    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.topicId = try container.decode(String.self, forKey: .topicId)
        self.topicName = try container.decode(String.self, forKey: .topicName)
        self.topicDescription = try container.decode(String.self, forKey: .topicDescription)
        self.channelSubscription = try container.decode([Channel].self, forKey: .channelSubscription)
    }
}
