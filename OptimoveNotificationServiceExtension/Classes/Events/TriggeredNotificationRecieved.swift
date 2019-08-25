//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class TriggeredNotificationRecieved: OptimoveEvent {

    struct Constants {
        static let name = "triggered_notification_recieved"
        struct Key {
            static let timestamp = "timestamp"
            static let appNS = "app_ns"
            static let actionID = "action_id"
            static let actionSerial = "action_serial"
            static let templateID = "template_id"
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

    let name = Constants.name
    let parameters: [String: Any]

    init(bundleId: String,
         campaign: TriggeredNotificationCampaign,
         timestamp: TimeInterval) {
        parameters = [
            Constants.Key.timestamp: Int(timestamp),
            Constants.Key.appNS: bundleId,
            Constants.Key.actionID: campaign.actionID,
            Constants.Key.actionSerial: campaign.actionSerial,
            Constants.Key.templateID: campaign.templateID,
            Constants.Key.eventDeviceType: Constants.Value.deviceType,
            Constants.Key.eventPlatform: Constants.Value.platform,
            Constants.Key.eventOS: Constants.Value.os,
            Constants.Key.eventNativeMobile: Constants.Value.nativeMobile
        ]
    }
}
