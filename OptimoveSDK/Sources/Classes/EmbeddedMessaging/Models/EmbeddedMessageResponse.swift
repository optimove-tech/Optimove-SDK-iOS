public typealias EmbeddedMessagesResponse = [String: EmbeddedMessagingContainer]


public struct EmbeddedMessagingAPIResponse: Codable {
    public let containers: [String: [EmbeddedMessage]]
}

 
