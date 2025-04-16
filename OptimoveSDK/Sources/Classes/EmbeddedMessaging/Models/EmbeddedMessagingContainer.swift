import Foundation


public struct EmbeddedMessagingContainer: Codable {
    public let containerId: String
    public let messages: [EmbeddedMessage]
}

