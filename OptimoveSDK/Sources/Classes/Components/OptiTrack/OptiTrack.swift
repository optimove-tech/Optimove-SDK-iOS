//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

typealias OptistreamEvent = OptimoveCore.OptistreamEvent
typealias OptistreamEventBuilder = OptimoveCore.OptistreamEventBuilder
typealias OptistreamNetworking = OptimoveCore.OptistreamNetworking

final class OptiTrack {

    private struct Constants {
        static let eventBatchLimit = 100
    }

    private let queue: OptistreamQueue
    private let optirstreamEventBuilder: OptistreamEventBuilder
    private let networking: OptistreamNetworking

    init(queue: OptistreamQueue,
         optirstreamEventBuilder: OptistreamEventBuilder,
         networking: OptistreamNetworking) {
        self.queue = queue
        self.optirstreamEventBuilder = optirstreamEventBuilder
        self.networking = networking
    }

}

extension OptiTrack: Component {

    func handle(_ operation: Operation) throws {
        switch operation {
        case let .report(event: event):
            track(event: event)
        case .dispatchNow:
            dispatch()
        default:
            break
        }
    }

}


private extension OptiTrack {

    func track(event: Event) {
        tryCatch {
            let event = try optirstreamEventBuilder.build(event: event)
            queue.enqueue(events: [event])
            networking.send(event: event) { [weak self] (result) in
                switch result {
                case .success(let response):
                    Logger.info(response.message)
                    self?.queue.remove(events: [event])
                case .failure(let error):
                    Logger.error(error.localizedDescription)
                }
            }
        }
    }

    func dispatch() {
        let events = queue.first(limit: Constants.eventBatchLimit)
        guard !events.isEmpty else {
            Logger.debug("No events for dispatch.")
            return
        }
        networking.send(events: events) { [weak self](result) in
            switch result {
            case .success(let response):
                Logger.info(response.message)
                self?.queue.remove(events: events)
            case .failure(let error):
                Logger.error(error.localizedDescription)
            }
        }
    }

}
