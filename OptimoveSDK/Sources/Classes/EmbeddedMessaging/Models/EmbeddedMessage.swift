import Foundation

public struct EmbeddedMessage: Codable {
    public let customerId: String
    public let isVisitor: Bool
    public let templateId: Int64
    public let title: String
    public let content: String?
    public let media: String?
    public let readAt: Date?
    public let url: String?
    public let engagementId: String
    public let payload: String
    public let campaignKind: Int
    public let executionDateTime: Date
    public let messageLayoutType: Int?
    public let expiryDate: Date?
    public let containerId: String?
    public let id: String
    public let createdAt: Date
    public let updatedAt: Date
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


