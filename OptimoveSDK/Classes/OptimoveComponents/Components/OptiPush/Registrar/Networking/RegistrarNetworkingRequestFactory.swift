//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class RegistrarNetworkingRequestFactory {

    struct Constants {
        static let path = "users"
        struct Endpoint {
            static let qa = URL(string: "https://mbaas-qa.optimove.net")!
            static let prod = URL(string: "https://mbaas.optimove.net")!
        }
    }

    private let storage: OptimoveStorage
    private let configuration: OptipushConfig
    private let encoder: JSONEncoder
    private let payloadBuilder: MbaasPayloadBuilder

    init(storage: OptimoveStorage,
         configuration: OptipushConfig,
         payloadBuilder: MbaasPayloadBuilder) {
        self.storage = storage
        self.configuration = configuration
        self.payloadBuilder = payloadBuilder
        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    func createRequest(operation: MbaasOperation) throws -> NetworkRequest {
        return NetworkRequest(
            method: method(for: operation),
            baseURL: try createURL(),
            headers: [
                HTTPHeader(field: .contentType, value: .json)
            ],
            httpBody: try createBody(operation: operation)
        )
    }

    private func method(for operation: MbaasOperation) -> HTTPMethod {
        switch operation {
        case .addOrUpdateUser:
            return .post
        case .migrateUser:
            return .put
        }
    }

    private func createURL() throws -> URL {
        let id = storage.customerID ?? storage.visitorID
        return (SDK.isStaging ? Constants.Endpoint.qa : Constants.Endpoint.prod)
            .appendingPathComponent(Constants.path)
            .appendingPathComponent(try unwrap(id))
    }

    private func createBody(operation: MbaasOperation) throws -> Data? {
        switch operation {
        case .addOrUpdateUser:
            return try encoder.encode(try payloadBuilder.createAddOrUpdateUserPayload())
        case .migrateUser:
            return try encoder.encode(try payloadBuilder.createMigrateUserPayload())
        }
    }
}
