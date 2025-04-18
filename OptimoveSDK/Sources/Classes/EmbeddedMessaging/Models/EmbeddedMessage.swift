import Foundation

public struct EmbeddedMessage: Codable {
    public let customerId: String
    public let isVisitor: Bool
    public let templateId: Int64
    public let title: String
    public let content: String?  // Optional, to allow null values
    public let media: String?  // Optional, to allow null values
    public let readAt: Int?  // Optional, to allow null values (null or missing readAt will be nil)
    public let url: String?  // Optional, to allow null values
    public let engagementId: String
    public let payload: [String: String]
    public let campaignKind: Int
    public let executionDateTime: String
    public let messageLayoutType: Int?  // Optional, to allow null values
    public let expiryDate: String?  // Optional, to allow null values
    public let containerId: String?  // Optional, to allow null values
    public let id: String
    public let createdAt: Int
    public let updatedAt: String?  // Optional, to allow null values
    public let deletedAt: String?  // Optional, to allow null values
}

public struct ReadMessageStatusUpdateRequest: Codable {
    public let brandId: String
    public let tenantId: String
    public let statusMetrics: [ReadMessageStatusMetric]
}

public struct ReadMessageStatusMetric: Codable {
    public let messageId: String
    public let engagementId: String
    public let executionDateTime: String
    public let campaignKind: Int
    public let customerId: String
    public let readAt: Int?
}
