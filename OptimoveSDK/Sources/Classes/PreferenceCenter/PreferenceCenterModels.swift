import Foundation

struct PreferenceCenterConfig: Codable {
    var region: Region
    var tenantId: Int
    var brandGroupId: String
}

public class Preferences: NSObject, Codable {
    var topics: [Topic]
    var channels: [Channel]

    public func getChannels() -> [Channel] {
        return channels
    }

    public func getTopics() -> [Topic] {
        return topics
    }

    public init(topics: [Topic], channels: [Channel]) {
        self.topics = topics
        self.channels = channels
    }

    required public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.topics = try container.decode([Topic].self, forKey: .topics)
        self.channels = try container.decode([Channel].self, forKey: .channels)
    }
}

public enum Channel: Int, Codable {
    case mobilePush = 489
    case webPush = 490
    case sms = 493
}

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

public class PreferenceUpdate: NSObject, Codable {
    var topicId: String
    var channelSubscription: [Channel]

    public init(topicId: String, channelSubscription: [Channel]) {
        self.topicId = topicId
        self.channelSubscription = channelSubscription
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.topicId = try container.decode(String.self, forKey: .topicId)
        self.channelSubscription = try container.decode([Channel].self, forKey: .channelSubscription)
    }
}
