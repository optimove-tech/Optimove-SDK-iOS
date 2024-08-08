import Foundation

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
