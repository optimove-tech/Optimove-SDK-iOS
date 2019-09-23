//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

protocol RealTimeHanlder {
    func handleOnSuccess(_ context: RealTimeEventContext, json: String)
    func handleOnError(_ context: RealTimeEventContext, error: Error)
}

final class RealTimeHanlderImpl {

    private var storage: OptimoveStorage

    init(storage: OptimoveStorage) {
        self.storage = storage
    }

}

extension RealTimeHanlderImpl: RealTimeHanlder {

    func handleOnSuccess(_ context: RealTimeEventContext, json: String) {
        context.onSuccess(json)
        switch context.type {
        case .setUserID:
            self.storage.realtimeSetUserIdFailed = false
        case .setUserEmail:
            self.storage.realtimeSetEmailFailed = false
        default:
            break
        }
    }

    func handleOnError(_ context: RealTimeEventContext, error: Error) {
        switch context.type {
        case .setUserID:
            self.storage.realtimeSetUserIdFailed = true
        case .setUserEmail:
            self.storage.realtimeSetEmailFailed = true
        default:
            break
        }
    }

}
