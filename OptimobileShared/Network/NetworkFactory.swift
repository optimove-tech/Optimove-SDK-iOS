//  Copyright © 2023 Optimove. All rights reserved.

import Foundation

final class NetworkFactory {
    var urlBuilder: UrlBuilder
    var authorization: HttpAuthorizationProtocol

    init(urlBuilder: UrlBuilder, authorization: HttpAuthorizationProtocol) {
        self.urlBuilder = urlBuilder
        self.authorization = authorization
    }

    func updateRegion(_ region: String) {
        urlBuilder = UrlBuilder(region: region)
    }

    func build(for service: UrlBuilder.Service) -> KSHttpClient {
        return KSHttpClient(
            baseUrl: urlBuilder.urlForService(service),
            requestFormat: .json,
            responseFormat: .json,
            authorization: authorization
        )
    }
}
