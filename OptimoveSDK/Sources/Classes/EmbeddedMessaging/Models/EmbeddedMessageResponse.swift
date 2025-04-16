public struct EmbeddedMessagingResponse: Codable {
    public let containers: [String: [EmbeddedMessage]]
}
