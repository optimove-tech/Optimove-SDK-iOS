//  Copyright © 2020 Optimove. All rights reserved.

import Foundation

public struct OptistreamResponse: Codable {
    public let status, message: String
    public init(status: String, message: String) {
        self.status = status
        self.message = message
    }
}

public protocol OptistreamNetworking {
    func send(event: OptistreamEvent, completion: @escaping (Result<OptistreamResponse, Error>) -> Void)
    func send(events: [OptistreamEvent], completion: @escaping (Result<OptistreamResponse, Error>) -> Void)
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
                OptistreamNetworkingImpl.handleResult(result: $0, for: [event], completion: completion)
            }
        } catch {
            completion(.failure(error))
        }
    }

    public func send(events: [OptistreamEvent], completion: @escaping (Result<OptistreamResponse, Error>) -> Void) {
        do {
            let request = try NetworkRequest(
                method: .post,
                baseURL: configuration.optitrackEndpoint,
                body: events
            )
            networkClient.perform(request) {
                OptistreamNetworkingImpl.handleResult(result: $0, for: events, completion: completion)
            }
        } catch {
            completion(.failure(error))
        }
    }

}

private extension OptistreamNetworkingImpl {

    static func handleResult(result: Result<NetworkResponse<Data?>, Error>,
                      for events: [OptistreamEvent],
                      completion: @escaping (Result<OptistreamResponse, Error>) -> Void) {
        completion(
            Result {
                do {
                    let response = try result.get().decode(to: OptistreamResponse.self)
                    Logger.debug(
                        """
                        Optistream succeed:
                            request: \n\(events.map{ $0.event }.joined(separator: "\n"))
                            response: \n\(response)
                        """
                    )
                    return response
                } catch {
                    Logger.error(
                        """
                        Optistream failed:
                            request: \n\(events.map{ $0.event }.joined(separator: "\n"))
                            reason: \n\(error.localizedDescription)
                        """
                    )
                    throw error
                }
            }
        )
    }

}
