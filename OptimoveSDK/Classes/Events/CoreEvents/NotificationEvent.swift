//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

class NotificationEvent: OptimoveCoreEvent {
    
    var name: String { return "" }
    var parameters: [String: Any]
    
    init(campaignDetails: CampaignDetails,
         timeStamp: TimeInterval = Date().timeIntervalSince1970) {
        parameters = [
            OptimoveKeys.Configuration.timestamp.rawValue: Int(timeStamp),
            OptimoveKeys.Configuration.appNs.rawValue: Bundle.main.bundleIdentifier!,
            OptimoveKeys.Configuration.campignId.rawValue: Int(campaignDetails.campaignId) ?? -1,
            OptimoveKeys.Configuration.actionSerial.rawValue: Int(campaignDetails.actionSerial) ?? -1,
            OptimoveKeys.Configuration.templateId.rawValue: Int(campaignDetails.templateId) ?? -1,
            OptimoveKeys.Configuration.engagementId.rawValue: Int(campaignDetails.engagementId) ?? -1,
            OptimoveKeys.Configuration.campaignType.rawValue: Int(campaignDetails.campaignType) ?? -1
        ]
    }
}

final class NotificationDeliveredEvent: NotificationEvent {
    override var name: String {
        return OptimoveKeys.Configuration.notificationDelivered.rawValue
    }
}

final class NotificationOpenedEvent: NotificationEvent {
    override var name: String {
        return OptimoveKeys.Configuration.notificationOpened.rawValue
    }
}

final class NotificationDismissedEvent: NotificationEvent {
    override var name: String {
        return OptimoveKeys.Configuration.notificationDismissed.rawValue
    }
}
