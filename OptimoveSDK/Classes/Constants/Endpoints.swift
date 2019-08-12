//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

struct Endpoints {

    struct Remote {
        static let tenantConfig = URL(string: "https://sdk-cdn.optimove.net/mobilesdkconfig")!
        static var globalConfig = tenantConfig
            .appendingPathComponent("global")
            .appendingPathComponent(SDK.environment.rawValue)
            .appendingPathComponent("configs")
            .appendingPathExtension("json")
    }

    struct Logger {
        static let defaultEndpint = URL(string: "https://us-central1-mobilepush-161510.cloudfunctions.net/reportLog")!
    }
}
