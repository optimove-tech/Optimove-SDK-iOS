//  Copyright © 2023 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class NetworkFactory {
    var urlBuilder: UrlBuilder
    var authorization: HttpAuthorizationProtocol
    var authManager: AuthManager?

    init(urlBuilder: UrlBuilder, authorization: HttpAuthorizationProtocol, authManager: AuthManager? = nil) {
        self.urlBuilder = urlBuilder
        self.authorization = authorization
        self.authManager = authManager
    }

    func build(for service: UrlBuilder.Service) -> KSHttpClient {
        return KSHttpClientImpl(
            serviceType: service,
            urlBuilder: urlBuilder,
            requestFormat: .json,
            responseFormat: .json,
            authorization: authorization,
            authManager: authManager
        )
    }
}
