import Foundation

class NotificationDelivered
{
    var name: String
    {
        return "notification_delivered"
    }
    var parameters: [String : Any]
    {
        return ["timestamp"   : timestamp,
                "app_ns"       : bundleId,
                "campaign_id"   : campaignId,
                "action_serial": actionSerial,
                "template_id"  : templateId,
                "engagement_id": engagementId,
                "campaign_type": campaignType,
                "event_device_type": "Mobile",
                "event_platform": "iOS",
                "event_os": currentDeviceOS,
                "event_native_mobile":  1
        ]
        
    }
    let campaignId: Int
    let actionSerial: Int
    let templateId: Int
    let engagementId:Int
    let campaignType: Int
    let timestamp: Int
    let bundleId:String
    let currentDeviceOS:String
    
    init(bundleId:String,campaignDetails:CampaignDetails,currentDeviceOS:String)
    {
        self.campaignId     = Int(campaignDetails.campaignId) ?? -1
        self.actionSerial   = Int(campaignDetails.actionSerial) ?? -1
        self.templateId     = Int(campaignDetails.templateId) ?? -1
        self.engagementId   = Int(campaignDetails.engagementId) ?? -1
        self.campaignType   = Int(campaignDetails.campaignType) ?? -1
        self.timestamp      = Int(Date().timeIntervalSince1970)
        self.bundleId       = bundleId
        self.currentDeviceOS = currentDeviceOS
    }
}
