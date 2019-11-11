//  Copyright © 2017 Optimove. All rights reserved.

import Foundation

struct OptimoveKeys {

    enum Registration: String, CodingKey {
        case tenantID = "tenant_id"
        case customerID = "public_customer_id"
        case visitorID = "visitor_id"
        case iosToken = "ios_token"
        case isVisitor = "is_visitor"
        case isConversion = "is_conversion"
        case origVisitorID = "orig_visitor_id"
        case deviceID = "device_id"
        case optIn = "opt_in"
        case optOut = "opt_out"
        case token = "token"
        case osVersion = "os_version"
        case registrationData = "registration_data"
        case unregistrationData = "unregistration_data"
        case apps = "apps"
        case bundleID = "app_ns"
        case successStatus = "success_status"
        case optOutStatus = "opt-out_status"
    }

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

    struct AddtionalAttributesValues {
        static let eventDeviceType = "Mobile"
        static let eventPlatform = "iOS"
        static let eventOs = "iOS \(operatingSystemVersionOnlyString)"
        static let eventNativeMobile = true
        private static let operatingSystemVersionOnlyString = ProcessInfo().operatingSystemVersionOnlyString
    }

    struct AdditionalAttributesKeys {
        static let eventDeviceType = "event_device_type"
        static let eventPlatform = "event_platform"
        static let eventOs = "event_os"
        static let eventNativeMobile = "event_native_mobile"
    }

    static let testTopicPrefix = "test_ios_"
}
