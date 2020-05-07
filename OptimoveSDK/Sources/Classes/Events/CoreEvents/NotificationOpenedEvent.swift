//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class NotificationOpenedEvent: Event {

    struct Constants {
        static let category = "optipush"
        struct Key {
            static let pushMetadata = "pushMetadata"
            static let timestamp = OptimoveKeys.Configuration.timestamp.rawValue
            static let appNS = OptimoveKeys.Configuration.appNs.rawValue
        }
    }

    init(
        bundleIdentifier: String,
        notificationType: NotificationCampaignType,
        pushMetadata: String
    ) {
        super.init(
            name: notificationType.eventName,
            category: Constants.category,
            context: [
                Constants.Key.timestamp: Int(Date().timeIntervalSince1970),
                Constants.Key.pushMetadata: pushMetadata,
                Constants.Key.appNS: bundleIdentifier
            ]
        )
    }

}

private extension NotificationCampaignType {

    var eventName: String {
        switch self {
        case .scheduled:
            return "notification_opened"
        case .triggered:
            return "triggered_notification_opened"
        }
    }

}
