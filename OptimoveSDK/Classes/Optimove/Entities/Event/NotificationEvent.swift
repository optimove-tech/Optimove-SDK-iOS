

import Foundation
class NotificationEvent:OptimoveCoreEvent
{
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
