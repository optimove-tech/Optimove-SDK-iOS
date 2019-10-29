//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class RegistrarNetworkingRequestFactory {

    private let storage: OptimoveStorage
    private let payloadBuilder: MbaasPayloadBuilder
    private let requestBuilder: ClientAPIRequestBuilder

    init(storage: OptimoveStorage,
         payloadBuilder: MbaasPayloadBuilder,
         requestBuilder: ClientAPIRequestBuilder) {
        self.storage = storage
        self.payloadBuilder = payloadBuilder
        self.requestBuilder = requestBuilder
    }

    func createRequest(operation: MbaasOperation) throws -> NetworkRequest {
        switch operation {
        case .setUser:
            return try requestBuilder.postAddMergeUser(
                userID: try storage.getInitialVisitorId(),
                userDevice: payloadBuilder.createSetUser()
            )
        case .addUserAlias:
            return try requestBuilder.putMigrateUser(
                try payloadBuilder.createAddUserAlias()
            )
        }
    }

}
