import Foundation

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
