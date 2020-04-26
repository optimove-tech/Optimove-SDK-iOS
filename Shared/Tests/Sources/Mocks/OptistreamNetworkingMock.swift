//  Copyright © 2020 Optimove. All rights reserved.

import OptimoveCore

final class OptistreamNetworkingMock: OptistreamNetworking {

    var assetOneEventFunction: ((_ event: OptistreamEvent, _ completion: (Result<OptistreamResponse, Error>) -> Void) -> Void)?

    func send(event: OptistreamEvent, completion: @escaping (Result<OptistreamResponse, Error>) -> Void) {

        assetOneEventFunction?(event, completion)
    }

    var assetManyEventsFunction: ((_ events: [OptistreamEvent], _ completion: (Result<OptistreamResponse, Error>) -> Void) -> Void)?

    func send(events: [OptistreamEvent], completion: @escaping (Result<OptistreamResponse, Error>) -> Void) {
        assetManyEventsFunction?(events, completion)
    }

}
