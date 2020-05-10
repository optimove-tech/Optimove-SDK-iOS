//  Copyright © 2020 Optimove. All rights reserved.

import OptimoveCore

final class OptistreamNetworkingMock: OptistreamNetworking {

    var assetEventsFunction: ((_ events: [OptistreamEvent], _ completion: (Result<Void, Error>) -> Void) -> Void)?

    func send(events: [OptistreamEvent], completion: @escaping (Result<Void, Error>) -> Void) {
        assetEventsFunction?(events, completion)
    }

}
