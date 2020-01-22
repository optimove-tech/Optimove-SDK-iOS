//  Copyright © 2020 Optimove. All rights reserved.

struct SetUser: Codable {

    struct Constants {
        static let os = "ios"
    }

    let deviceID, appNS, os, deviceToken: String
    let optIn, isDev: Bool

    enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case appNS = "app_ns"
        case os
        case deviceToken = "device_token"
        case optIn = "opt_in"
        case isDev = "is_dev"
    }
}
