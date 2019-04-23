//
//  Constants.swift
//  iOS-SDK
//
//  Created by Mobile Developer Optimove on 04/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import UIKit

struct OptimoveKeys {
    enum Registration: String {
        case tenantID               = "tenant_id"
        case customerID             = "public_customer_id"
        case visitorID              = "visitor_id"
        case iOSToken               = "ios_token"
        case isVisitor              = "is_visitor"
        case isConversion           = "is_conversion"
        case origVisitorID          = "orig_visitor_id"
        case deviceID               = "device_id"
        case optIn                  = "opt_in"
        case optOut                 = "opt_out"
        case token                  = "token"
        case osVersion              = "os_version"
        case registrationData       = "registration_data"
        case unregistrationData     = "unregistration_data"
        case apps                   = "apps"
        case bundleID               = "app_ns"
        case successStatus          = "success_status"
        case optOutStatus           = "opt-out_status"
    }

    enum Configuration: String {

        case ios                                        = "ios"

        // MARK: - events configurations

        case setAdvertisingId                           = "set_advertising_id"
        case setUserId                                  = "set_user_id_event"
        case setEmail                                   = "set_email_event"
        case advertisingId                              = "advertising_id"

        case deviceId                                   = "device_id"
        case appNs                                      = "app_ns"
        case platform                                   = "platform"

        case visitorId                                  = "visitor_id"
        case notificationDelivered                      = "notification_delivered"
        case timestamp                                  = "timestamp"
        case campignId                                  = "campaign_id"
        case actionSerial                               = "action_serial"
        case templateId                                 = "template_id"
        case engagementId                               = "engagement_id"
        case campaignType                               = "campaign_type"
        case notificationOpened                         = "notification_opened"
        case notificationDismissed                      = "notification_dismissed"

        case originalVisitorId                          = "originalVisitorId"
        case userId                                     = "user_id"
        case realtimeUserId                             = "userId"
        case realtimeupdatedVisitorId                   = "updatedVisitorId"
        case optipushOptIn                              = "optipush_opt_in"
        case optipushOptOut                             = "optipush_opt_out"
        case setUserAgent                               = "user_agent_header_event"
        case userAgentHeader1                            = "user_agent_header1"
        case userAgentHeader2                            = "user_agent_header2"
        case email                                      = "email"

    }

    enum Notification: String {
        case title                  = "title"
        case body                   = "content"
        case dynamicLinks           = "dynamic_links"
        case ios                    = "ios"
        case campaignId             = "campaign_id"
        case actionSerial           = "action_serial"
        case templateId             = "template_id"
        case engagementId           = "engagement_id"
        case campaignType           = "campaign_type"
        case isOptipush             = "is_optipush"
        case collapseId             = "collapse_Key"
        case dynamikLink            = "dynamic_link"
        case isOptimoveSdkCommand   = "is_optimove_sdk_command"
        case command                = "command"
    }

    enum Topics: String {
        case fcmToken   = "fcmToken"
        case topics     = "topics"
    }

    struct AddtionalAttributesValues {
        static let eventDeviceType = "Mobile"
        static let eventPlatform    = "iOS"
        static let eventOs          =  "iOS \(ProcessInfo().operatingSystemVersionOnlyString)"
        static let eventNativeMobile = true
    }
    struct AdditionalAttributesKeys {
        static let eventDeviceType = "event_device_type"
        static let eventPlatform    = "event_platform"
        static let eventOs          = "event_os"
        static let eventNativeMobile = "event_native_mobile"
    }
}

struct NotificationCategoryIdentifiers {
    static let dismiss    = "dismiss"
}

enum HttpHeader: String {
    case contentType    = "Content-Type"
    case userAgent      = "User-Agent"
}

enum HttpMethod: String {
    case get        = "GET"
    case post       = "POST"
    case head       = "HEAD"
    case put        = "PUT"
    case delete     = "DELETE"
    case options    = "OPTIONS"
    case connect    = "CONNECT"
}

enum MediaType: String {
    case json = "application/json"
}

var TenantID: Int? {
    get {
        return OptimoveUserDefaults.shared.siteID
    }
}
var Version: String? {
    get {
        return OptimoveUserDefaults.shared.version
    }
}
var CustomerID: String? {
    get {
        return OptimoveUserDefaults.shared.customerID
    }
}
var UserEmail: String? {
    get {
        return OptimoveUserDefaults.shared.userEmail
    }
}
var VisitorID: String {
    get {
        return OptimoveUserDefaults.shared.visitorID!
    }
}

var InitialVisitorID: String {
    get {
        return OptimoveUserDefaults.shared.initialVisitorId!
    }
}
var DeviceID: String {
    get {
        return SHA1.hexString(from: UIDevice.current.identifierForVendor?.uuidString ?? "")!.replacingOccurrences(of: " ", with: "")
    }
}
