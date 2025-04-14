import Foundation


public struct EmbeddedMessage: Codable {
    public let customerId: String
    public let isVisitor: Bool
    public let templateId: Int64
    public let title: String
    public let content: String?
    public let media: String?
    public let readAt: String?
    public let url: String?
    public let engagementId: String
    public let payload: [String: String]
    public let campaignKind: Int
    public let executionDateTime: String
    public let messageLayoutType: Int
    public let expiryDate: String
    public let containerId: String?
    public let id: String
    public let createdAt: Int
    public let updatedAt: String?
    public let deletedAt: String?
}

