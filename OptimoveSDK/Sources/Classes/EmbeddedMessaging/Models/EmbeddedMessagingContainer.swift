import Foundation


public struct EmbeddedMessagingContainer: Codable {
    public let containerId: String
    public let messages: [EmbeddedMessage]
}

public struct EmbeddedMessageOptions: Codable {
    let containerId: String
    let limit: Int?
}
