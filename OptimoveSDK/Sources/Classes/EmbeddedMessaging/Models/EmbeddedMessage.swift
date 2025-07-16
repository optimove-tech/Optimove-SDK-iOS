import Foundation

public struct EmbeddedMessage: Codable {
    public let customerId: String
    public let isVisitor: Bool
    public let templateId: Int64
    public let title: String
    public let content: String?
    public let media: String?
    public let readAt: Int64?
    public let url: String?
    public let engagementId: String
    public let payload: [String: AnyCodable]
    public let campaignKind: Int
    public let executionDateTime: String // kept as ISO8601 string
    public let messageLayoutType: Int?
    public let expiryDate: String?
    public let containerId: String
    public let id: String
    public let createdAt: Int64
    public let updatedAt: Int64?
    public let deletedAt: String?
}

public typealias EmbeddedMessagesResponse = [String: EmbeddedMessagingContainer]

internal struct EmbeddedMessagingAPIResponse: Codable {
    public let containers: [String: [EmbeddedMessage]]
}

public struct ReadAtMetricRequest: Codable {
    public let brandId: String
    public let tenantId: String
    public let statusMetrics: [ReadMessageStatusMetric]
}

public struct ReadMessageStatusMetric: Codable {
    public let messageId: String
    public let engagementId: String
    public let executionDateTime: Date
    public let campaignKind: Int
    public let customerId: String
    public let readAt: Int?
}

public struct ClickMetricRequest: Codable {
    public let brandId: String
    public let tenantId: String
    public let statusMetrics: [ClickMetric]
}

public struct ClickMetric: Codable {
    public let messageId: String
    public let engagementId: String
    public let executionDateTime: Date
    public let campaignKind: Int
    public let customerId: String
    public let now: String
}

public struct EmbeddedMessagingConfig: Codable {
    let region: String
    let tenantId: Int
    let brandId: String
}

public struct EmbeddedMessagingContainer: Codable {
    public let containerId: String
    public let messages: [EmbeddedMessage]
}

public struct ContainerRequestOptions: Codable {
    let containerId: String
    let limit: Int?
}

public enum EventType: String, Codable {
    case markAsRead = "markAsRead"
    case markAsUnread = "markAsUnread"
    case delete = "delete"
    case clickMetric = "clickMetric"
}

struct EventBody: Codable {
    let timestamp: String
    let uuid: String
    let eventType: String
    let customerId: String
    let visitorId: String
    let context: [String: String]
}

// MARK: - AnyCodable to support arbitrary JSON objects in payload
public struct AnyCodable: Codable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let string as String:
            try container.encode(string)
        case let dict as [String: AnyCodable]:
            try container.encode(dict)
        case let array as [AnyCodable]:
            try container.encode(array)
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported value"))
        }
    }
}
