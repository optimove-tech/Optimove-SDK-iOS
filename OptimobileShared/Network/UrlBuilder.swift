//  Copyright © 2022 Optimove. All rights reserved.

import Foundation

public class UrlBuilder {
    public enum Service: CaseIterable {
        case crm
        case ddl
        case events
        case iar
        case media
        case push
    }

    public typealias ServiceUrlMap = [Service: String]

    let baseUrlMap: ServiceUrlMap

    convenience init(region: String) {
        self.init(baseUrlMap: UrlBuilder.defaultMapping(for: region))
    }

    required init(baseUrlMap: ServiceUrlMap) {
        for s in Service.allCases {
            if baseUrlMap[s] == nil {
                fatalError("baseUrlMap must contain an entry for all Service cases")
            }
        }

        self.baseUrlMap = baseUrlMap
    }

    func urlForService(_ service: Service) -> URL {
        let baseUrl = baseUrlMap[service]!
        return URL(string: baseUrl)!
    }

    static func defaultMapping(for region: String) -> ServiceUrlMap {
        return [
            .crm: "https://crm-\(region).kumulos.com",
            .ddl: "https://links-\(region).kumulos.com",
            .events: "https://events-\(region).kumulos.com",
            .iar: "https://iar.app.delivery",
            .media: "https://i-\(region).app.delivery",
            .push: "https://push-\(region).kumulos.com",
        ]
    }
}
