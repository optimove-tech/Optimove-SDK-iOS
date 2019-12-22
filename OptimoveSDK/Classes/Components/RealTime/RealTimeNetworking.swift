//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

protocol RealTimeNetworking {
    func report(event: RealtimeEvent, completion: @escaping (Result<String, Error>) -> Void) throws
}

final class RealTimeNetworkingImpl {

    private let networkClient: NetworkClient
    private let realTimeRequestBuildable: RealTimeRequestBuildable
    private let configuration: RealtimeConfig

    init(networkClient: NetworkClient,
         realTimeRequestBuildable: RealTimeRequestBuildable,
         configuration: RealtimeConfig) {
        self.networkClient = networkClient
        self.realTimeRequestBuildable = realTimeRequestBuildable
        self.configuration = configuration
    }

}

extension RealTimeNetworkingImpl: RealTimeNetworking {

    func report(event: RealtimeEvent,
                completion: @escaping (Result<String, Error>) -> Void) throws {
        let request = try realTimeRequestBuildable.createReportEventRequest(
            event: event,
            gateway: configuration.realtimeGateway
        )
        networkClient.perform(request) { (result) in
            completion(
                Result {
                    return try cast(String(data: try result.get().unwrap(), encoding: .utf8))
                }
            )
        }
    }

}
