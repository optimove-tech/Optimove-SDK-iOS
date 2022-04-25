//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ApiRequestFactory {

    private let storage: OptimoveStorage
    private let payloadBuilder: ApiPayloadBuilder
    private let requestBuilder: ApiRequestBuilder

    init(storage: OptimoveStorage,
         payloadBuilder: ApiPayloadBuilder,
         requestBuilder: ApiRequestBuilder) {
        self.storage = storage
        self.payloadBuilder = payloadBuilder
        self.requestBuilder = requestBuilder
    }

    func createRequest(operation: ApiOperation) throws -> NetworkRequest {
        switch operation {
        case .setInstallation:
            return try requestBuilder.postSetInstallation(
                model: try payloadBuilder.createInstallation()
            )
        }
    }

}
