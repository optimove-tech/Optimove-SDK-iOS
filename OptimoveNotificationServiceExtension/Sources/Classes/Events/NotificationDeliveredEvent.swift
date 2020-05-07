//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class NotificationDeliveredEvent: Event {

    struct Constants {
        struct Key {
            static let identityToken = "identity_token"
            static let timestamp = "timestamp"
            static let appNS = "app_ns"
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
         notificationType: NotificationCampaignType,
         identityToken: String,
         timestamp: Date = Date()) {
        super.init(
            name: notificationType.eventName,
            category: "optipush",
            context: [
                Constants.Key.identityToken: identityToken,
                Constants.Key.timestamp: timestamp.timeIntervalSince1970.seconds,
                Constants.Key.appNS: bundleId,
                Constants.Key.eventDeviceType: Constants.Value.deviceType,
                Constants.Key.eventPlatform: Constants.Value.platform,
                Constants.Key.eventOS: Constants.Value.os,
                Constants.Key.eventNativeMobile: Constants.Value.nativeMobile
            ],
            timestamp: timestamp
        )
    }
}

private extension NotificationCampaignType {

    var eventName: String {
        switch self {
        case .scheduled:
            return "notification_delivered"
        case .triggered:
            return "triggered_notification_received"
        }
    }
}
