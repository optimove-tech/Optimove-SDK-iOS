//
//  Constants.swift
//  iOS-SDK
//
//  Created by Mobile Developer Optimove on 04/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import UIKit

struct Keys
{
    enum Registration: String
    {
        case tenantID               = "tenant_id"
        case customerID             = "public_customer_id"
        case visitorID              = "visitor_id"
        case iOSToken               = "ios_token"
        case isVisitor              = "is_visitor"
        case isCopnversion          = "is_conversion"
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
    
    enum Configuration: String
    {
        //MARK: General configuration
        case enableOptitrack                            = "enable_optitrack"
        case enableOptipush                             = "enable_optipush"
        case enableVisitors                             = "enable_visitors"
        case enableRealtime                             = "enable_realtime"
        case tenantId                                   = "tenant_id"
        
        //MARK: - optitrack configurations
        case optitrackMetaData                          = "optitrack_metadata"
        case sendUserAgentHeader                        = "send_user_agent_header"
        case enableAdvertisingIdReport                  = "enable_advertising_id_report"
        case enableHeartBeatTimer                       = "enable_heart_beat_timer"
        case heartBeatTimer                             = "heart_beat_timer"
        case eventCategoryName                          = "event_category_name"
        case eventIdCustomDimensionId                   = "event_id_custom_dimension_id"
        case eventNameCustomDimensionId                 = "event_name_custom_dimension_id"
        case visitCustomDimensionsStartId               = "visit_custom_dimensions_start_id"
        case maxVisitCustomDimensions                   = "max_visit_custom_dimensions"
        case actionCustomDimensionsStartId              = "action_custom_dimensions_start_id"
        case maxActionCustomDimensions                  = "max_action_custom_dimensions"
        case optitrackEndpoint                          = "optitrack_endpoint"
        case siteId                                     = "site_id"
        
        //MARK: - optipush configuration
        case mobile                                     = "mobile"
        case optipushMetaData                           = "optipush_metadata"
        case registrationServiceOtherEndPoint           = "other_registration_service_endpoint"
        case registrationServiceRegistrationEndPoint    = "only_registration_service_endpoint"
        case firebaseProjectKeys                        = "firebase_project_keys"
        case clientServiceProjectKeys                   = "clients_service_project_keys"
        case appIds                                     = "app_ids"
        case appId                                      = "app_id"
        case ios                                        = "ios"
        case webApiKey                                  = "web_api_key"
        case dbUrl                                      = "db_url"
        case senderId                                   = "sender_id"
        case storageBucket                              = "storage_bucket"
        case projectId                                  = "project_id"
        case clientServiceAppNs                         = "ios.master.app"
        
        //MARK:  - events configurations
       
        case events                                     = "events"
        case setAdvertisingId                           = "set_advertising_id"
        case id                                         = "id"
        case supportedOnOptitrack                       = "supported_on_optitrack"
        case supportedOnRealTime                        = "supported_on_realtime"
        case parameters                                 = "parameters"
        case advertisingId                              = "advertising_id"
        case optional                                   = "optional"
        case name                                       = "name"
        case type                                       = "type"
        case optiTrackDimensionId                       = "optitrack_dimension_id"
        case deviceId                                   = "device_id"
        case appNs                                      = "app_ns"
        
        case stitchEvent                                = "stitch_event"
        case sourcePublicCustomerId                     = "source_public_customer_id"
        case sourceVisitorId                            = "source_visitor_id"
        case targetVsitorId                             = "target_visitor_id"
        
        case notificationDelivered                      = "notification_delivered"
        case timestamp                                  = "timestamp"
        case campignId                                  = "campaign_id"
        case actionSerial                               = "action_serial"
        case templateId                                 = "template_id"
        case engagementId                               = "engagement_id"
        case campaignType                               = "campaign_type"
        case notificationOpened                         = "notification_opened"
        case notificationDismissed                      = "notification_dismissed"
        case beforeSetUserId                            = "before_set_user_id"
        case originalVisitorId                          = "original_visitor_id"
        case userId                                     = "user_id"
        case optipushOptIn                              = "optipush_opt_in"
        case optipushOptOut                             = "optipush_opt_out"
        case afterSetUserId                             = "after_set_user_id"
        case setUserAgent                               = "user_agent_header_event"
        case userAgentHeader                            = "user_agent_header"
        case setScreenVisit                             = "set_screen_visit"
        case screenName                                 = "screen_name"
    }
    
    enum Notification : String
    {
        case title              = "title"
        case body               = "content"
        case category           = "category"
        case dynamicLinks       = "dynamic_links"
        case ios                = "ios"
        case campaignId         = "campaign_id"
        case actionSerial       = "action_serial"
        case templateId         = "template_id"
        case engagementId       = "engagement_id"
        case campaignType       = "campaign_type"
        case isOptipush         = "is_optipush"
        case collapseId         = "collapse_Key"
        case dynamikLink        = "dynamic_link"
    }
}

struct NotificationCategoryIdentifiers
{
    static let dismiss    = "dismiss"
}

enum HttpHeader: String
{
    case contentType    = "Content-Type"
    case userAgent      = "User-Agent"
}

enum HttpMethod: String
{
    case get        = "GET"
    case post       = "POST"
    case head       = "HEAD"
    case put        = "PUT"
    case delete     = "DELETE"
    case options    = "OPTIONS"
    case connect    = "CONNECT"
}

enum MediaType: String
{
    case json = "application/json"
}

var TenantID : Int?
{
    get {
        return UserInSession.shared.siteID
    }
}
var Verison :String?
{
    get {
        return UserInSession.shared.version
    }
}
var CustomerID :String? {
    get {
        return UserInSession.shared.customerID
    }
}
var VisitorID :String?
{
    get {
        return UserInSession.shared.visitorID
    }
}
var DeviceID : String
{
    get
    {
        return UIDevice.current.identifierForVendor?.uuidString ?? ""
    }
}
var OSVersion : String
{
    get
    {
        return UIDevice.current.systemVersion
    }
}

var ShouldLogToConsole : Bool
{
    #if DEBUG
        return true
    #else
        return false
    #endif
}

typealias UserAgent = String

