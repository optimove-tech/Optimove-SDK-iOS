//
//  OptimovePredefinedEvents.swift
//  OptimoveSDK
//
//  Created by Mobile Developer Optimove on 08/10/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import UIKit
import AdSupport

class SetAdvertisingId : OptimoveEvent
{
    var name: String
    {
        return Keys.Configuration.setAdvertisingId.rawValue
    }
    
    var parameters: [String : Any]
    {
        return [Keys.Configuration.advertisingId.rawValue   : ASIdentifierManager.shared().advertisingIdentifier.uuidString ,
                Keys.Configuration.deviceId.rawValue        : DeviceID,
                Keys.Configuration.appNs.rawValue           : Bundle.main.bundleIdentifier!]
    }
}

class NotificationEvent:OptimoveEvent
{
    enum NotificationEventKeys:String  {
        case appNs             = "app_ns"
        case timeStamp         = "timestamp"
        case actionName        = "action_name"
        case campaignId        = "campaign_id"
        case templateId        = "template_id"
        case campaignType      = "campaign_type"
        case actionSerial      = "action_serial"
        case engagementId      = "engagement_id"
        case pairsDelimeter    = "&"
        case keyValueDelimeter = "="
    }
    
    func backupString() -> String
    {
        var stringEvent = String()
        stringEvent += NotificationEventKeys.actionName.rawValue
        stringEvent += NotificationEventKeys.keyValueDelimeter.rawValue
        stringEvent += name
        stringEvent += NotificationEventKeys.pairsDelimeter.rawValue
        stringEvent += NotificationEventKeys.timeStamp.rawValue
        stringEvent += NotificationEventKeys.keyValueDelimeter.rawValue
        stringEvent += String(Int(Date().timeIntervalSince1970))
        stringEvent += NotificationEventKeys.pairsDelimeter.rawValue
        stringEvent += NotificationEventKeys.campaignId.rawValue
        stringEvent += NotificationEventKeys.keyValueDelimeter.rawValue
        stringEvent += campaignId.description
        stringEvent += NotificationEventKeys.pairsDelimeter.rawValue
        stringEvent += NotificationEventKeys.templateId.rawValue
        stringEvent += NotificationEventKeys.keyValueDelimeter.rawValue
        stringEvent += templateId.description
        stringEvent += NotificationEventKeys.pairsDelimeter.rawValue
        stringEvent += NotificationEventKeys.actionSerial.rawValue
        stringEvent += NotificationEventKeys.keyValueDelimeter.rawValue
        stringEvent += actionSerial.description
        stringEvent += NotificationEventKeys.pairsDelimeter.rawValue
        stringEvent += NotificationEventKeys.engagementId.rawValue
        stringEvent += NotificationEventKeys.keyValueDelimeter.rawValue
        stringEvent += engagementId.description
        stringEvent += NotificationEventKeys.pairsDelimeter.rawValue
        stringEvent += NotificationEventKeys.campaignType.rawValue
        stringEvent += NotificationEventKeys.keyValueDelimeter.rawValue
        stringEvent += campaignType.description
        
        return stringEvent
    }
    
    static func newInstance(from string:String) -> NotificationEvent?
    {
        var actionName: String?
        var timestamp: Int?
        var campaignId: Int?
        var templateId: Int?
        var actionSerial: Int?
        var engagementId: Int?
        var campaignType: Int?
        
        let pairs = string.components(separatedBy: NotificationEventKeys.pairsDelimeter.rawValue)
        for pair in pairs
        {
            let components = pair.components(separatedBy: NotificationEventKeys.keyValueDelimeter.rawValue)
            let (key,val) = (components[0],components[1])
            switch key
            {
            case NotificationEventKeys.actionName.rawValue:
                actionName = val
                
            case NotificationEventKeys.timeStamp.rawValue:
                if let double = Double(val) {
                    timestamp = Int(double)
                }
                else {return nil}
            case NotificationEventKeys.campaignId.rawValue:
                if let id = Int(val){
                    campaignId = id
                } else {return nil}
            case NotificationEventKeys.templateId.rawValue:
                if let id = Int(val){
                    templateId = id
                } else {return nil}
            case NotificationEventKeys.actionSerial.rawValue:
                if let id = Int(val){
                    actionSerial = id
                }else {return nil}
            case NotificationEventKeys.engagementId.rawValue:
                if let id = Int(val){
                    engagementId = id
                } else {return nil}
            case NotificationEventKeys.campaignType.rawValue:
                if let id = Int(val) {
                    campaignType = id
                } else {return nil}
            default: return nil
            }
        }
        
        guard let actionNameFinal   = actionName,
            let campaignIdFinal         = campaignId,
            let actionSerialFinal       = actionSerial,
            let templateIdFinal         = templateId,
            let engagementIdFinal       = engagementId,
            let campaignTypeFinal       = campaignType,
            let timestampFinal          = timestamp
            else { return nil }
        switch actionNameFinal
        {
        case Keys.Configuration.notificationDelivered.rawValue:
            return NotificationDelivered(campaignDetails: CampaignDetails(campaignId: String(campaignIdFinal), actionSerial: String(actionSerialFinal), templateId: String(templateIdFinal), engagementId: String(engagementIdFinal), campaignType: String(campaignTypeFinal)), timeStamp: timestampFinal)
        case Keys.Configuration.notificationDismissed.rawValue:
            return NotificationDismissed(campaignDetails: CampaignDetails(campaignId: String(campaignIdFinal), actionSerial: String(actionSerialFinal), templateId: String(templateIdFinal), engagementId: String(engagementIdFinal), campaignType: String(campaignTypeFinal)), timeStamp: timestampFinal)
        case Keys.Configuration.notificationOpened.rawValue:
            return NotificationOpened(campaignDetails: CampaignDetails(campaignId: String(campaignIdFinal), actionSerial: String(actionSerialFinal), templateId: String(templateIdFinal), engagementId: String(engagementIdFinal), campaignType: String(campaignTypeFinal)), timeStamp: timestampFinal)
        default:
            return nil
        }
    }
    
    var name: String
    {
        return ""
    }
    var parameters: [String : Any]
    {
        return [Keys.Configuration.timestamp.rawValue   : timestamp,
                Keys.Configuration.appNs.rawValue       : appNs,
                Keys.Configuration.campignId.rawValue   : campaignId,
                Keys.Configuration.actionSerial.rawValue: actionSerial,
                Keys.Configuration.templateId.rawValue  : templateId,
                Keys.Configuration.engagementId.rawValue: engagementId,
                Keys.Configuration.campaignType.rawValue:campaignType]
    }
    var campaignId: Int
    var actionSerial: Int
    var templateId: Int
    var engagementId:Int
    var campaignType: Int
    var timestamp: Int
    let appNs:      String
    
    
    init(campaignDetails:CampaignDetails, timeStamp:Int = Int(Date().timeIntervalSince1970))
    {
        self.campaignId     = Int(campaignDetails.campaignId) ?? -1
        self.actionSerial   = Int(campaignDetails.actionSerial) ?? -1
        self.templateId     = Int(campaignDetails.templateId) ?? -1
        self.engagementId   = Int(campaignDetails.engagementId) ?? -1
        self.campaignType   = Int(campaignDetails.campaignType) ?? -1
        timestamp           = timeStamp
        appNs               = Bundle.main.bundleIdentifier!
    }
    init()
    {
        self.campaignId     = -1
        self.actionSerial   = -1
        self.templateId     = -1
        self.engagementId   = -1
        self.campaignType   = -1
        self.timestamp      = -1
        self.appNs          = Bundle.main.bundleIdentifier!
    }
}

class NotificationDelivered: NotificationEvent
{
    override var name: String
    {
        return Keys.Configuration.notificationDelivered.rawValue
    }
}

class NotificationOpened : NotificationEvent
{
    override var name: String
    {
        return Keys.Configuration.notificationOpened.rawValue
    }
}

class NotificationDismissed : NotificationEvent
{
    override var name: String
    {
        return Keys.Configuration.notificationDismissed.rawValue
    }
}

class SetUserId :OptimoveEvent
{
    var name: String
    {
        return ""
    }
    var parameters: [String : Any]
    {
        guard let visitorId = VisitorID, let customerId = CustomerID else {
            return [Keys.Configuration.originalVisitorId.rawValue   : VisitorID as Any,
                    Keys.Configuration.userId.rawValue              : CustomerID as Any]
        }
        return [Keys.Configuration.originalVisitorId.rawValue   : visitorId,
                Keys.Configuration.userId.rawValue              : customerId]
    }
}

class BeforeSetUserId: SetUserId
{
   override var name: String
    {
        return Keys.Configuration.beforeSetUserId.rawValue
    }
}

class AfterSetUserId: SetUserId
{
    override var name: String
    {
        return Keys.Configuration.afterSetUserId.rawValue
    }
}

class Opt :OptimoveEvent
{
    var name: String
    {
        return ""
    }
    var parameters: [String : Any]
    {
        return [Keys.Configuration.timestamp.rawValue   : Int(Date().timeIntervalSince1970),
                Keys.Configuration.appNs.rawValue       : Bundle.main.bundleIdentifier!,
                Keys.Configuration.deviceId.rawValue    : DeviceID]
    }
}

class OptipushOptIn: Opt
{
    override var name: String
    {
        return Keys.Configuration.optipushOptIn.rawValue
    }
}

class OptipushOptOut: Opt
{
    override var name: String
    {
        return Keys.Configuration.optipushOptOut.rawValue
    }
}

class SetUserAgent: OptimoveEvent
{
    init(userAgent:String){
        self.userAgent = userAgent
    }
    var userAgent:String
    
    
    var name: String {return Keys.Configuration.setUserAgent.rawValue}
    
    var parameters: [String : Any]
    {
        return [Keys.Configuration.userAgentHeader.rawValue: self.userAgent]
    }
}
@objc public class ScreenName: NSObject,OptimoveEvent
{
    let screenName: String
    
    public var name: String
    {
        return Keys.Configuration.setScreenVisit.rawValue
    }
    
    public var parameters: [String : Any]
    {
        return [Keys.Configuration.screenName.rawValue: screenName]
    }
    public init(screenName: String)
    {
        self.screenName = screenName
    }
}

