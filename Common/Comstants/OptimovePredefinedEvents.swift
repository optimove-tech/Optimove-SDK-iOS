//
//  OptimovePredefinedEvents.swift
//  OptimoveSDK
//
//  Created by Mobile Developer Optimove on 08/10/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import UIKit
import AdSupport

struct SetAdvertisingId : OptimoveEvent
{
    var name: String
    {
        return Keys.Configuration.setAdvertisingId.rawValue
    }
    
    var paramaeters: [String : Any]
    {
        return [Keys.Configuration.advertisingId.rawValue   : ASIdentifierManager.shared().advertisingIdentifier.uuidString ,
                Keys.Configuration.deviceId.rawValue        : UIDevice.current.identifierForVendor!.uuidString,
                Keys.Configuration.appNs.rawValue           : Bundle.main.bundleIdentifier!]
    }
}

class NotificationEvent
{
    var paramaeters: [String : Any]
    {
        return [Keys.Configuration.timestamp.rawValue   : Int(Date().timeIntervalSince1970),
                Keys.Configuration.appNs.rawValue       : Bundle.main.bundleIdentifier!,
                Keys.Configuration.campignId.rawValue   : campaignId,
                Keys.Configuration.actionSerial.rawValue: actionSerial,
                Keys.Configuration.templateId.rawValue  : templateId,
                Keys.Configuration.engagementId.rawValue: engagementId,
                Keys.Configuration.campaignType.rawValue:campaignType]
    }
    let campaignId: Int
    let actionSerial: Int
    let templateId: Int
    let engagementId:Int
    let campaignType: Int
    
    init(campaignDetails:CampaignDetails)
    {
        self.campaignId = Int(campaignDetails.campaignId) ?? -1
        self.actionSerial = Int(campaignDetails.actionSerial) ?? -1
        self.templateId = Int(campaignDetails.templateId) ?? -1
        self.engagementId = Int(campaignDetails.engagementId) ?? -1
        self.campaignType = Int(campaignDetails.campaignType) ?? -1
    }
}

class NotificationDelivered: NotificationEvent,OptimoveEvent
{
     var name: String
    {
        return Keys.Configuration.notificationDelivered.rawValue
    }
}

class NotificationOpened : NotificationEvent, OptimoveEvent
{
    var name: String
    {
        return Keys.Configuration.notificationOpened.rawValue
    }
}

class NotificationDismissed : NotificationEvent, OptimoveEvent
{
    var name: String
    {
        return Keys.Configuration.notificationDismissed.rawValue
    }
}

struct BeforeSetUserId: OptimoveEvent
{
    var name: String
    {
        return Keys.Configuration.beforeSetUserId.rawValue
    }
    var paramaeters: [String : Any]
    {
        return [Keys.Configuration.originalVisitorId.rawValue   : UserInSession.shared.visitorID!,
                Keys.Configuration.userId.rawValue              : UserInSession.shared.customerID!]
    }
}

struct AfterSetUserId: OptimoveEvent
{
    var name: String
    {
        return Keys.Configuration.afterSetUserId.rawValue
    }
    
    var paramaeters: [String : Any]
    {
        return [Keys.Configuration.originalVisitorId.rawValue   : UserInSession.shared.visitorID!,
                Keys.Configuration.userId.rawValue              : UserInSession.shared.customerID!]
    }
}

struct OptipushOptIn: OptimoveEvent
{
    var name: String
    {
        return Keys.Configuration.optipushOptIn.rawValue
    }
    
    var paramaeters: [String : Any]
    {
        return [Keys.Configuration.timestamp.rawValue   : Int(Date().timeIntervalSince1970),
                Keys.Configuration.appNs.rawValue       : Bundle.main.bundleIdentifier!]
    }
}

struct ScreenName: OptimoveEvent
{
    let screenName: String
    var name: String
    {
        return Keys.Configuration.setScreenVisit.rawValue
    }
    
    var paramaeters: [String : Any]
    {
        return [Keys.Configuration.screenName.rawValue: screenName]
    }
}

struct OptipushOptOut: OptimoveEvent
{
    var name: String
    {
        return Keys.Configuration.optipushOptOut.rawValue
    }
    
    var paramaeters: [String : Any]
    {
        return [Keys.Configuration.timestamp.rawValue   : Int(Date().timeIntervalSince1970),
                Keys.Configuration.appNs.rawValue       : Bundle.main.bundleIdentifier!]
    }
}


struct SetUserAgent: OptimoveEvent
{
    var userAgent:String
    
    var name: String {return Keys.Configuration.setUserAgent.rawValue}
    
    var paramaeters: [String : Any]
    {
        return [Keys.Configuration.userAgentHeader.rawValue: self.userAgent]
    }
}
