//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

protocol RegistrarNetworking {
    func sendToMbaas(model: BaseMbaasModel, completion: @escaping (Result<String, Error>) -> Void)
}

final class RegistrarNetworkingImpl {

    private let networkClient: NetworkClient
    private let requestBuilder: RegistrarNetworkingRequestBuilder

    init(networkClient: NetworkClient,
         requestBuilder: RegistrarNetworkingRequestBuilder) {
        self.networkClient = networkClient
        self.requestBuilder = requestBuilder
    }

}

extension RegistrarNetworkingImpl: RegistrarNetworking {

    func sendToMbaas(model: BaseMbaasModel, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            let request = try requestBuilder.createRequest(model: model)
            if let httpBody = request.httpBody, let json = String(data: httpBody, encoding: .utf8) {
                Logger.debug("OptiPush: Send request \(model.operation.rawValue) to \(request.baseURL) payload \(json)")
            }
            networkClient.perform(request) { (result) in
                completion(
                    Result {
                        do {
                            let data = try result.get().unwrap()
                            let string: String = try cast(String(data: data, encoding: .utf8))
                            Logger.debug("OptiPush: Request \(model.operation.rawValue) success. Response: \(string)")
                            return string
                        } catch {
                            Logger.error(
                                "OptiPush: Request \(model.operation.rawValue) failed. Reason: \(error.localizedDescription)"
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
