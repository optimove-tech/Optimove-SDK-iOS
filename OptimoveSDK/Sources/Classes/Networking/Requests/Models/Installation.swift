//  Copyright © 2020 Optimove. All rights reserved.

struct Installation: Codable {

    struct Constants {
        static let os = "ios"
        static let pushProvider = "apns"
    }

    struct Metadata: Codable {
        let sdkVersion: String
        let appVersion: String
        let osVersion: String
        let deviceModel: String
    }

    let os = Constants.os
    let pushProvider = Constants.pushProvider
    let customerID: String?
    let deviceToken, installationID, appNS, visitorID: String
    let optIn, isDev: Bool
    let metadata: Metadata
    let isPushCampaignsDisabled: Bool
    let firstRunTime: Int64

}
