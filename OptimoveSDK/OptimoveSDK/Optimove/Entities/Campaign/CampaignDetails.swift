//
//  CampaignDetails.swift
//  
//
//  Created by Elkana Orbach on 20/11/2017.
//

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
        guard let campaignId   = (userInfo[Keys.Notification.campaignId.rawValue]   as? String),
            let actionSerial = (userInfo[Keys.Notification.actionSerial.rawValue]   as? String),
            let templateId   = (userInfo[Keys.Notification.templateId.rawValue]     as? String),
            let engagementId = (userInfo[Keys.Notification.engagementId.rawValue]   as? String),
            let campaignType = (userInfo[Keys.Notification.campaignType.rawValue]   as? String)
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
