//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

protocol ApiNetworking {
    func sendToMbaas(operation: ApiOperation, completion: @escaping (Result<String, Error>) -> Void)
}

final class ApiNetworkingImpl {

    private let networkClient: NetworkClient
    private let requestFactory: ApiRequestFactory

    init(networkClient: NetworkClient,
         requestFactory: ApiRequestFactory) {
        self.networkClient = networkClient
        self.requestFactory = requestFactory
    }

}

extension ApiNetworkingImpl: ApiNetworking {

    func sendToMbaas(operation: ApiOperation, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            let request = try requestFactory.createRequest(operation: operation)
            networkClient.perform(request) { (result) in
                completion(
                    Result {
                        do {
                            let data = try result.get().unwrap()
                            let string: String = try cast(String(data: data, encoding: .utf8))
                            Logger.debug("OptiPush: Request \(operation.description) success. Response: \(string)")
                            return string
                        } catch {
                            Logger.error(
                                "OptiPush: Request \(operation.description) failed. Reason: \(error.localizedDescription)"
                            )
                            throw error
                        }
                    }
                )
            }
        } catch {
            completion(.failure(error))
        }
    }
}
