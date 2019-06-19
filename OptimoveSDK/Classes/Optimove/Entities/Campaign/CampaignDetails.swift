//
//  CampaignDetails.swift
//  
//

import Foundation

struct CampaignDetails {
    let campaignId: String
    let actionSerial: String
    let templateId: String
    let engagementId: String
    let campaignType: String
}

extension CampaignDetails {
    static func extractCampaignDetails(from userInfo: [AnyHashable: Any]) -> CampaignDetails? {
        guard let campaignId = (userInfo[OptimoveKeys.Notification.campaignId.rawValue] as? String),
            let actionSerial = (userInfo[OptimoveKeys.Notification.actionSerial.rawValue] as? String),
            let templateId = (userInfo[OptimoveKeys.Notification.templateId.rawValue] as? String),
            let engagementId = (userInfo[OptimoveKeys.Notification.engagementId.rawValue] as? String),
            let campaignType = (userInfo[OptimoveKeys.Notification.campaignType.rawValue] as? String)
        else {
            return nil
        }

        return CampaignDetails(
            campaignId: campaignId,
            actionSerial: actionSerial,
            templateId: templateId,
            engagementId: engagementId,
            campaignType: campaignType
        )
    }
}
