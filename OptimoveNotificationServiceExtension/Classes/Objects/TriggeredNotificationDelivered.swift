//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class TriggeredNotificationDelivered: OptimoveEvent {

    let name = "triggered_notification_received"

    let timestamp: Int
    let bundleId: String
    let currentDeviceOS: String
    let deviceType = "Mobile"
    let isNativeMobile = true
    let platform = "iOS"

    let actionSerial: Int
    let templateId: Int
    let actionId: Int

    var parameters: [String: Any] {
        return [
            "timestamp": timestamp,
            "app_ns": bundleId,
            "action_id": actionId,
            "action_serial": actionSerial,
            "template_id": templateId,
            "event_device_type": "Mobile",
            "event_platform": "iOS",
            "event_os": currentDeviceOS,
            "event_native_mobile": true,
        ]
    }

    init(bundleId: String,
         campaign: TriggeredNotificationCampaign) {
        self.actionSerial = campaign.actionSerial
        self.templateId = campaign.templateID
        self.actionId = campaign.actionID
        self.timestamp = Int(Date().timeIntervalSince1970)
        self.bundleId = bundleId
        self.currentDeviceOS = "iOS \(ProcessInfo().operatingSystemVersionOnlyString)"
    }
}
