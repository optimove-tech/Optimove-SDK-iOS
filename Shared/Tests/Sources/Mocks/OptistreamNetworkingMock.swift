//  Copyright © 2020 Optimove. All rights reserved.

import OptimoveCore

final class OptistreamNetworkingMock: OptistreamNetworking {

    var assetEventsFunction: ((_ events: [OptistreamEvent], _ completion: (Result<OptistreamResponse, Error>) -> Void) -> Void)?

    func send(events: [OptistreamEvent], completion: @escaping (Result<OptistreamResponse, Error>) -> Void) {
        assetEventsFunction?(events, completion)
    }

}
