//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

public struct OptistreamResponse: Codable {
    let status, message: String
}

public protocol OptistreamNetworking {
    func send(event: OptistreamEvent, completion: @escaping (Result<OptistreamResponse, Error>) -> Void)
}

public final class OptistreamNetworkingImpl {

    private let networkClient: NetworkClient
    private let configuration: OptitrackConfig

    public init(
        networkClient: NetworkClient,
        configuration : OptitrackConfig
    ) {
        self.networkClient = networkClient
        self.configuration = configuration
    }

}

extension OptistreamNetworkingImpl: OptistreamNetworking {

    public func send(event: OptistreamEvent, completion: @escaping (Result<OptistreamResponse, Error>) -> Void) {
        do {
            let request = try NetworkRequest(
                method: .post,
                baseURL: configuration.optitrackEndpoint,
                body: event
            )
            networkClient.perform(request) {
                OptistreamNetworkingImpl.handleResult(result: $0, for: event, completion: completion)
            }
        } catch {
            completion(.failure(error))
        }
    }

}

private extension OptistreamNetworkingImpl {

    static func handleResult(result: Result<NetworkResponse<Data?>, Error>,
                      for event: OptistreamEvent,
                      completion: @escaping (Result<OptistreamResponse, Error>) -> Void) {
        completion(
            Result {
                do {
                    let response = try result.get().decode(to: OptistreamResponse.self)
                    Logger.debug("Optistream succeed:\n\trequest: \(event.event)\n\tresponse: \(response)")
                    return response
                } catch {
                    Logger.error(
                        "Optistream failed:\n\trequest: \(event.event)\n\treason: \(error.localizedDescription)"
                    )
                    throw error
                }
            }
        )
    }

}
