//  Copyright © 2017 Optimove. All rights reserved.

import Foundation

struct OptimoveKeys {

    enum Configuration: String {
        case ios = "ios"
        case setAdvertisingId = "set_advertising_id"
        case setUserId = "set_user_id_event"
        case setEmail = "set_email_event"
        case advertisingId = "advertising_id"
        case deviceId = "device_id"
        case appNs = "app_ns"
        case platform = "platform"
        case visitorId = "visitor_id"
        case timestamp = "timestamp"
        case campignId = "campaign_id"
        case actionSerial = "action_serial"
        case templateId = "template_id"
        case engagementId = "engagement_id"
        case campaignType = "campaign_type"
        case originalVisitorId = "originalVisitorId"
        case userId = "user_id"
        case realtimeUserId = "userId"
        case realtimeupdatedVisitorId = "updatedVisitorId"
        case optipushOptIn = "optipush_opt_in"
        case optipushOptOut = "optipush_opt_out"
        case setUserAgent = "user_agent_header_event"
        case email = "email"
    }

    enum Notification: String {
        case title = "title"
        case body = "content"
        case dynamicLinks = "dynamic_links"
        case ios = "ios"
        case campaignId = "campaign_id"
        case actionSerial = "action_serial"
        case templateId = "template_id"
        case actionId = "action_id"
        case engagementId = "engagement_id"
        case campaignType = "campaign_type"
        case isOptipush = "is_optipush"
        case collapseId = "collapse_Key"
        case dynamicLink = "dynamic_link"
        case command = "command"
    }

}
