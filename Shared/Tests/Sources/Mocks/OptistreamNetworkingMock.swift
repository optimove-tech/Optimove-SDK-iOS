//  Copyright © 2020 Optimove. All rights reserved.

import OptimoveCore

final class OptistreamNetworkingMock: OptistreamNetworking {

    var assetEventsFunction: ((_ events: [OptistreamEvent], _ completion: (Result<Void, NetworkError>) -> Void) -> Void)?

    func send(events: [OptistreamEvent], completion: @escaping (Result<Void, NetworkError>) -> Void) {
        assetEventsFunction?(events, completion)
    }

}
