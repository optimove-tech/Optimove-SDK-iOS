//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public struct Endpoints {

    public struct Logger {
        public static let defaultEndpint = URL(string:
            "https://us-central1-mobilepush-161510.cloudfunctions.net/reportLog"
        )!
    }

    public struct Remote {

        public struct TenantConfig {
            public static let url = URL(string: "https://sdk-cdn.optimove.net/mobilesdkconfig")!
        }

        public struct GlobalConfig {
            private static let version = "v1"
            private static let globalBase = base
                .appendingPathComponent("global")
                .appendingPathComponent(version)
            private static let fileName = "configs.json"

            public static func url(_ env: Environment) -> URL {
                return globalBase.appendingPathComponent(env.rawValue).appendingPathComponent(fileName)
            }
        }

        private static let base = URL(string: "https://sdk-cdn.optimove.net/configs/mobile")!
    }
}
