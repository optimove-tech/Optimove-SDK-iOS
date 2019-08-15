//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ScheduledNotificationDelivered: OptimoveEvent {

    let name = "notification_delivered"
    let campaignId: Int
    let actionSerial: Int
    let templateId: Int
    let engagementId: Int
    let campaignType: Int
    let timestamp: Int
    let bundleId: String
    let currentDeviceOS: String
    let deviceType = "Mobile"
    let isNativeMobile = true
    let platform = "iOS"

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

    init(bundleId: String,
         campaign: ScheduledNotificationCampaign) {
        self.campaignId = campaign.campaignID
        self.actionSerial = campaign.actionSerial
        self.templateId = campaign.templateID
        self.engagementId = campaign.engagementID
        self.campaignType = campaign.campaignType
        self.timestamp = Int(Date().timeIntervalSince1970)
        self.bundleId = bundleId
        self.currentDeviceOS = "iOS \(ProcessInfo().operatingSystemVersionOnlyString)"
    }
}
