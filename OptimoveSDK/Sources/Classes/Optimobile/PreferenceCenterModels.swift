import Foundation

struct PreferenceCenterConfig: Codable {
    var region: Region
    var tenantId: Int
    var brandGroupId: String
}

public struct Preferences: Codable {
    var topics: [Topic]
    var channels: [Channel]
}

enum Channel: Int, Codable {
    case mobilePush = 489
    case webPush = 490
    case sms = 493
}

struct Topic: Codable {
    var topicId: String
    var topicName: String
    var topicDescription: String
    var channelSubscription: [Channel]
}

public struct PreferenceUpdate: Codable {
    var topicId: String
    var subscribedChannels: [Channel]
}
