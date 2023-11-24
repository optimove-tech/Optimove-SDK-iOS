//  Copyright © 2022 Optimove. All rights reserved.

import Foundation

public class UrlBuilder {
    enum Error: LocalizedError {
        case regionNotSet
        case failedToBuildUrl(String?)

        var errorDescription: String? {
            switch self {
            case .regionNotSet:
                return "Region not set"
            case let .failedToBuildUrl(string):
                return "Failed to build URL: \(string ?? "nil")"
            }
        }
    }

    public enum Service: CaseIterable {
        case crm
        case ddl
        case events
        case iar
        case media
        case push
    }

    public typealias ServiceUrlMap = [Service: String]

    let storage: KeyValPersistenceHelper.Type
    var region: String {
        get throws {
            if let regionString = storage.object(forKey: OptimobileUserDefaultsKey.REGION.rawValue) as? String {
                return regionString
            }
            throw Error.regionNotSet
        }
    }

    required init(storage: KeyValPersistenceHelper.Type) {
        self.storage = storage
    }

    func urlForService(_ service: Service) throws -> URL {
        let baseUrlMap = try UrlBuilder.defaultMapping(for: region)
        guard let baseUrl = baseUrlMap[service], let url = URL(string: baseUrl) else {
            throw Error.failedToBuildUrl(baseUrlMap[service])
        }
        return url
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
