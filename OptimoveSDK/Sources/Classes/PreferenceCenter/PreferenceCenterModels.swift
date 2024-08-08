import Foundation

struct PreferenceCenterConfig: Codable {
    let region: Region
    let tenantId: Int
    let brandGroupId: String
}

public enum Channel: Int, Codable {
    case mobilePush = 489
    case webPush = 490
    case sms = 493
}

public class PreferencesObjc: NSObject, Codable {
    @nonobjc let preferences: Preferences

    init(preferences: Preferences) {
        self.preferences = preferences
    }

    public init(topics: [TopicObjc], channels: [Channel]) {
        self.preferences = Preferences(
            topics: topics.map { $0.topic },
            channels: channels
        )
    }
}

public class TopicObjc: NSObject, Codable {
    @nonobjc let topic: Preferences.Topic
    public var topicId: String {
        return topic.topicId
    }

    public var topicName: String {
        return topic.topicName
    }

    public var topicDescription: String {
        return topic.topicDescription
    }

    public var channelSubscription: [Channel] {
        return topic.channelSubscription
    }
}

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

public class PreferenceUpdateRequestObjc: NSObject, Codable {
    @nonobjc let preferenceUpdateRequest: PreferenceUpdateRequest
    public var topicId: String {
        return preferenceUpdateRequest.topicId
    }

    public var channelSubscription: [Channel] {
        return preferenceUpdateRequest.channelSubscription
    }

    init(preferenceUpdateRequest: PreferenceUpdateRequest) {
        self.preferenceUpdateRequest = preferenceUpdateRequest
    }

    public init(topicId: String, channelSubscription: [Channel]) {
        self.preferenceUpdateRequest = PreferenceUpdateRequest(topicId: topicId, channelSubscription: channelSubscription)
    }
}

public struct PreferenceUpdateRequest: Codable {
    public let topicId: String
    public let channelSubscription: [Channel]

    public init(topicId: String, channelSubscription: [Channel]) {
        self.topicId = topicId
        self.channelSubscription = channelSubscription
    }
}
