//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class RegistrarNetworkingRequestFactory {

    private let storage: OptimoveStorage
    private let payloadBuilder: MbaasPayloadBuilder
    private let requestBuilder: ClientAPIRequestBuilder
    private let userService: UserService

    init(storage: OptimoveStorage,
         payloadBuilder: MbaasPayloadBuilder,
         requestBuilder: ClientAPIRequestBuilder,
         userService: UserService) {
        self.storage = storage
        self.payloadBuilder = payloadBuilder
        self.requestBuilder = requestBuilder
        self.userService = userService
    }

    func createRequest(operation: MbaasOperation) throws -> NetworkRequest {
        switch operation {
        case .addOrUpdateUser:
            return try requestBuilder.postAddMergeUser(
                userID: try userService.getUserID(),
                userDevice: payloadBuilder.createAddMergeUser()
            )
        case .migrateUser:
            return try requestBuilder.putMigrateUser(
                try payloadBuilder.createMigrateUser()
            )
        }
    }

}
