//  Copyright © 2026 Optimove. All rights reserved.

import Foundation

/// Parameters for opening an Adact embedded campaign.
///
/// Maps to the Web / Android SDK `openAdactCampaign` contract:
/// `{adactUrl}/embedded/{campaignId}?cid=&customerIdToken=`
public struct OpenAdactParams {
    public var campaignId: Int?
    public var cid: String?
    public var token: String?

    public init(campaignId: Int? = nil, cid: String? = nil, token: String? = nil) {
        self.campaignId = campaignId
        self.cid = cid
        self.token = token
    }
}
