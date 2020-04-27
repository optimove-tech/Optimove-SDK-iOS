//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ScheduledNotificationDelivered: Event {

    private struct Constants {
        static let name = "notification_delivered"
        struct Key {
            static let timestamp = "timestamp"
            static let appNS = "app_ns"
            static let campaignID = "campaign_id"
            static let actionSerial = "action_serial"
            static let templateID = "template_id"
            static let engagementID = "engagement_id"
            static let campaignType = "campaign_type"
            static let eventDeviceType = "event_device_type"
            static let eventPlatform = "event_platform"
            static let eventOS = "event_os"
            static let eventNativeMobile = "event_native_mobile"
        }
        struct Value {
            static let deviceType = "Mobile"
            static let platform = "iOS"
            static let nativeMobile = true
            static let os = "iOS \(ProcessInfo().operatingSystemVersionOnlyString)"
        }
    }

    init(bundleId: String,
         campaign: ScheduledNotificationCampaign,
         timestamp: Int) {
        super.init(
            name: Constants.name,
            category: "optipush",
            context: [
                Constants.Key.timestamp: timestamp,
                Constants.Key.appNS: bundleId,
                Constants.Key.campaignID: campaign.campaignID,
                Constants.Key.actionSerial: campaign.actionSerial,
                Constants.Key.templateID: campaign.templateID,
                Constants.Key.engagementID: campaign.engagementID,
                Constants.Key.campaignType: campaign.campaignType ?? -1,
                Constants.Key.eventDeviceType: Constants.Value.deviceType,
                Constants.Key.eventPlatform: Constants.Value.platform,
                Constants.Key.eventOS: Constants.Value.os,
                Constants.Key.eventNativeMobile: Constants.Value.nativeMobile
            ],
            timestamp: timestamp
        )
    }
}
