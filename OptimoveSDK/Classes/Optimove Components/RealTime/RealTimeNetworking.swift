// Copiright 2019 Optimove

import Foundation

protocol RealTimeNetworking {
    func report(event: RealtimeEvent, completion: @escaping (Result<String, Error>) -> Void) throws
}

final class RealTimeNetworkingImpl {

    private let networkClient: NetworkClient
    private let realTimeRequestBuildable: RealTimeRequestBuildable
    private let metaDataProvider: MetaDataProvider<RealtimeMetaData>

    init(networkClient: NetworkClient,
         realTimeRequestBuildable: RealTimeRequestBuildable,
         metaDataProvider: MetaDataProvider<RealtimeMetaData>) {
        self.networkClient = networkClient
        self.realTimeRequestBuildable = realTimeRequestBuildable
        self.metaDataProvider = metaDataProvider
    }

}

extension RealTimeNetworkingImpl: RealTimeNetworking {

    func report(event: RealtimeEvent,
                completion: @escaping (Result<String, Error>) -> Void) throws {
        let metadata = try metaDataProvider.getMetaData()
        let request = try realTimeRequestBuildable.createReportEventRequest(event: event, metadata: metadata)
        networkClient.perform(request) { (result) in
            completion(
                Result {
                    return try cast(String(data: try result.get().unwrap(), encoding: .utf8))
                }
            )
        }
    }

}
