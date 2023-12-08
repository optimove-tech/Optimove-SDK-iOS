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

    // Overrided urls
    var runtimeUrlsMap: ServiceUrlMap?

    // Computed property to allow overriding the default URL map
    var urlMap: ServiceUrlMap {
        get throws {
            if let runtimeUrlsMap = runtimeUrlsMap {
                return runtimeUrlsMap
            }
            return try UrlBuilder.defaultMapping(for: region)
        }
    }

    var region: String {
        get throws {
            if let regionString = storage.object(forKey: OptimobileUserDefaultsKey.REGION.rawValue) as? String {
                return regionString
            }
            throw Error.regionNotSet
        }
    }

    required init(storage: KeyValPersistenceHelper.Type, runtimeUrlsMap: ServiceUrlMap? = nil) {
        self.storage = storage
        if let runtimeUrlsMap = runtimeUrlsMap, isValidateUrlMap(urlsMap: runtimeUrlsMap) {
            self.runtimeUrlsMap = runtimeUrlsMap
        }
    }

    func urlForService(_ service: Service) throws -> URL {
        let baseUrlMap = try urlMap
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

    func isValidateUrlMap(urlsMap: ServiceUrlMap) -> Bool {
        for s in Service.allCases {
            if urlsMap[s] == nil {
                assertionFailure("UrlMap must contain an entry for all Service case. Missing key: \(s)")
                return false
            }
        }
        return true
    }
}
