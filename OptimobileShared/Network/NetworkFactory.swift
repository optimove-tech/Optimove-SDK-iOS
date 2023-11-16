//  Copyright © 2023 Optimove. All rights reserved.

import Foundation

final class NetworkFactory {
    private var urlBuilder: UrlBuilder

    init(urlBuilder: UrlBuilder) {
        self.urlBuilder = urlBuilder
    }

    func updateRegion(_ region: String) {
        urlBuilder = UrlBuilder(region: region)
    }

    func build(for service: UrlBuilder.Service) -> KSHttpClient {
        return KSHttpClient(
            baseUrl: urlBuilder.urlForService(service),
            requestFormat: .json,
            responseFormat: .json
        )
    }
}
