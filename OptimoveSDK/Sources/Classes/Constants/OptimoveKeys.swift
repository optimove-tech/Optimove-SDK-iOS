//  Copyright © 2017 Optimove. All rights reserved.

import Foundation

enum OptimoveKeys {
    enum Configuration: String {
        case ios
        case setAdvertisingId = "set_advertising_id"
        case setUserId = "set_user_id_event"
        case setEmail = "set_email_event"
        case advertisingId = "advertising_id"
        case deviceId = "device_id"
        case appNs = "app_ns"
        case platform
        case visitorId = "visitor_id"
        case timestamp
        case campignId = "campaign_id"
        case actionSerial = "action_serial"
        case templateId = "template_id"
        case engagementId = "engagement_id"
        case campaignType = "campaign_type"
        case originalVisitorId
        case userId = "user_id"
        case realtimeUserId = "userId"
        case realtimeupdatedVisitorId = "updatedVisitorId"
        case setUserAgent = "user_agent_header_event"
        case email
    }
}
