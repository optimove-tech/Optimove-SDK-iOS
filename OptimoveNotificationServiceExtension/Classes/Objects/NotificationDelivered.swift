import Foundation

class NotificationDelivered {
    
    var name: String {
        return "notification_delivered"
    }

    var parameters: [String: Any] {
        return [
            "timestamp": timestamp,
            "app_ns": bundleId,
            "campaign_id": campaignId,
            "action_serial": actionSerial,
            "template_id": templateId,
            "engagement_id": engagementId,
            "campaign_type": campaignType,
            "event_device_type": "Mobile",
            "event_platform": "iOS",
            "event_os": currentDeviceOS,
            "event_native_mobile": true,
        ]

    }
    let campaignId: Int
    let actionSerial: Int
    let templateId: Int
    let engagementId: Int
    let campaignType: Int
    let timestamp: Int
    let bundleId: String
    let currentDeviceOS: String

    init(bundleId: String, campaignDetails: CampaignDetails, currentDeviceOS: String) {
        self.campaignId = campaignDetails.campaignId
        self.actionSerial = campaignDetails.actionSerial
        self.templateId = campaignDetails.templateId
        self.engagementId = campaignDetails.engagementId
        self.campaignType = campaignDetails.campaignType
        self.timestamp = Int(Date().timeIntervalSince1970)
        self.bundleId = bundleId
        self.currentDeviceOS = currentDeviceOS
    }
}
