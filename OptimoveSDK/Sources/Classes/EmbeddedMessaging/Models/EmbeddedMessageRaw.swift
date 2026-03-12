import Foundation

// Internal raw decoding struct that mirrors the server JSON shape.
// Decodes date fields as strings and payload as AnyCodable, then maps to the public EmbeddedMessage.
// This avoids adding a custom init(from:) to the public EmbeddedMessage struct.
internal struct EmbeddedMessageRaw: Decodable {
    let customerId: String
    let isVisitor: Bool
    let templateId: Int64
    let title: String
    let content: String?
    let media: String?
    let readAt: String?
    let url: String?
    let engagementId: String?
    let payload: AnyCodable
    let campaignKind: Int
    let executionDateTime: String
    let messageLayoutType: Int?
    let expiryDate: String?
    let containerId: String?
    let id: String
    let createdAt: String
    let updatedAt: String
    let deletedAt: String?

    func toEmbeddedMessage() -> EmbeddedMessage {
        EmbeddedMessage(
            customerId: customerId,
            isVisitor: isVisitor,
            templateId: templateId,
            title: title,
            content: content,
            media: media,
            readAt: Self.parseDate(readAt),
            url: url,
            engagementId: engagementId,
            payload: Self.serializePayload(payload),
            campaignKind: campaignKind,
            executionDateTime: Self.parseDate(executionDateTime) ?? Date(timeIntervalSince1970: 0),
            messageLayoutType: messageLayoutType,
            expiryDate: Self.parseDate(expiryDate),
            containerId: containerId,
            id: id,
            createdAt: Self.parseDate(createdAt) ?? Date(timeIntervalSince1970: 0),
            updatedAt: Self.parseDate(updatedAt) ?? Date(timeIntervalSince1970: 0),
            deletedAt: deletedAt
        )
    }

    // MARK: - Date parsing
    static func parseDate(_ str: String?) -> Date? {
        guard let str = str, !str.isEmpty else { return nil }
        return isoWithFractional.date(from: str) ?? isoWithoutFractional.date(from: str)
    }
    
    // ISO8601DateFormatter handles varying fractional second precision (2, 3, 6 digits) natively
    private static let isoWithFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoWithoutFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    // MARK: - Payload serialization
    private static func serializePayload(_ value: AnyCodable) -> String {
        guard let data = try? JSONEncoder().encode(value),
              let str = String(data: data, encoding: .utf8) else { return "{}" }
        return str
    }
}

internal struct EmbeddedMessagingAPIResponse {
    let containers: [String: [EmbeddedMessage]]
}

extension EmbeddedMessagingAPIResponse: Decodable {
    init(from decoder: Decoder) throws {
        let root = try decoder.container(keyedBy: CodingKeys.self)
        let raw = try root.decode([String: [EmbeddedMessageRaw]].self, forKey: .containers)
        containers = raw.mapValues { $0.map { $0.toEmbeddedMessage() } }
    }

    private enum CodingKeys: String, CodingKey {
        case containers
    }
}
