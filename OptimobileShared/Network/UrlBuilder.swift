//  Copyright © 2022 Optimove. All rights reserved.

import Foundation

class UrlBuilder {
    public enum Service: CaseIterable {
        case crm
        case ddl
        case events
        case iar
        case media
        case push
    }

    public typealias ServiceUrlMap = [Service: URL]

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
        return baseUrl
    }

    static func defaultMapping(for region: String) -> ServiceUrlMap {
        return [
            .crm: URL(string: "https://crm-\(region).kumulos.com")!,
            .ddl: URL(string: "https://links-\(region).kumulos.com")!,
            .events: URL(string: "https://events-\(region).kumulos.com")!,
            .iar: URL(string: "https://iar.app.delivery")!,
            .media: URL(string: "https://i-\(region).app.delivery")!,
            .push: URL(string: "https://push-\(region).kumulos.com")!,
        ]
    }
}
