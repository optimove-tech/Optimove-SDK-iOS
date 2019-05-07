import Foundation

struct CampaignDetails
{
    let campaignId:String
    let actionSerial : String
    let templateId : String
    let engagementId: String
    let campaignType: String
}

extension CampaignDetails
{
    static func extractCampaignDetails(from userInfo: [AnyHashable : Any] ) -> CampaignDetails?
    {
        guard let campaignId  = (userInfo["campaign_id"]   as? String),
            let actionSerial = (userInfo["action_serial"]   as? String),
            let templateId   = (userInfo["template_id"]     as? String),
            let engagementId = (userInfo["engagement_id"]   as? String),
            let campaignType = (userInfo["campaign_type"]   as? String)
            else
        {
            return nil
        }
        
        return CampaignDetails(campaignId: campaignId,
                               actionSerial: actionSerial,
                               templateId: templateId,
                               engagementId: engagementId,
                               campaignType: campaignType)
    }
}
