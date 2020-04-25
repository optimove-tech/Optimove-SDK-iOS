//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ScheduledNotificationOpened: Event {

    struct Constants {
        static let name = "notification_opened"
        static let category = "optipush"
        struct Key {
            static let timestamp = OptimoveKeys.Configuration.timestamp.rawValue
            static let appNS = OptimoveKeys.Configuration.appNs.rawValue
            static let templateID = OptimoveKeys.Notification.templateId.rawValue
            static let actionSerial = OptimoveKeys.Notification.actionSerial.rawValue
            static let campignID = OptimoveKeys.Configuration.campignId.rawValue
            static let engagementID = OptimoveKeys.Notification.engagementId.rawValue
            static let campaignType = OptimoveKeys.Notification.campaignType.rawValue
        }
    }

    init(bundleIdentifier: String, campaign: ScheduledNotificationCampaign) {
        super.init(
            name: Constants.name,
            category: Constants.category,
            context: [
                Constants.Key.timestamp: Int(Date().timeIntervalSince1970),
                Constants.Key.appNS: bundleIdentifier,
                Constants.Key.templateID: campaign.templateID,
                Constants.Key.actionSerial: campaign.actionSerial,
                Constants.Key.campignID: campaign.campaignID,
                Constants.Key.engagementID: campaign.engagementID,
                Constants.Key.campaignType: campaign.campaignType ?? -1
            ]
        )
    }

}
