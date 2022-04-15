// Copyright © 2022 Optimove. All rights reserved.

import Foundation

public enum Service : CaseIterable {
    case crm
    case ddl
    case events
    case iar
    case media
    case push
}

public typealias ServiceUrlMap = [Service:String]

class UrlBuilder {
    let baseUrlMap : ServiceUrlMap

    init(baseUrlMap:ServiceUrlMap) {
        for s in Service.allCases {
            if baseUrlMap[s] == nil {
                fatalError("baseUrlMap must contain an entry for all Service cases")
            }
        }

        self.baseUrlMap = baseUrlMap
    }

    func urlForService(_ service:Service) -> String {
        let baseUrl = baseUrlMap[service]!
        return baseUrl
    }

    static func defaultMapping(region: String) -> ServiceUrlMap {
        return [
            .crm : "https://crm-" + region + ".kumulos.com",
            .ddl : "https://links-" + region + ".kumulos.com",
            .events : "https://events-" + region + ".kumulos.com",
            .push : "https://push-" + region + ".kumulos.com",
            .iar : "https://iar.app.delivery",
            .media : "https://i.app.delivery",
        ]
    }
}
