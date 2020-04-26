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
    private var isDispatching = false
    private var dispatchInterval: TimeInterval = 30.0 {
        didSet {
            startDispatchTimer()
        }
    }
    private var dispatchTimer: Timer?

    init(queue: OptistreamQueue,
         optirstreamEventBuilder: OptistreamEventBuilder,
         networking: OptistreamNetworking) {
        self.queue = queue
        self.optirstreamEventBuilder = optirstreamEventBuilder
        self.networking = networking
    }

    private func startDispatchTimer() {
        self.startDispatchTimer()
        guard dispatchInterval > 0  else { return }
        if let dispatchTimer = dispatchTimer {
            dispatchTimer.invalidate()
            self.dispatchTimer = nil
        }
        dispatchTimer = Timer.scheduledTimer(
            timeInterval: dispatchInterval,
            target: self,
            selector: #selector(self.dispatch),
            userInfo: nil,
            repeats: false
        )
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
            let streamEvent = try optirstreamEventBuilder.build(event: event)
            queue.enqueue(events: [streamEvent])
            if event.isRealtime {
                networking.send(event: streamEvent) { [weak self] (result) in
                    switch result {
                    case .success(let response):
                        Logger.info(response.message)
                        self?.queue.remove(events: [streamEvent])
                    case .failure(let error):
                        Logger.error(error.localizedDescription)
                    }
                }
            }
        }
    }

    @objc func dispatch() {
        guard !isDispatching else {
            Logger.debug("Tracker is already dispatching.")
            return
        }
        guard queue.eventCount > 0 else {
            Logger.debug("No need to dispatch. Dispatch queue is empty.")
            startDispatchTimer()
            return
        }
        Logger.info("Start dispatching events")
        isDispatching = true
        dispatchBatch()
    }

    private func dispatchBatch() {
        let events = queue.first(limit: Constants.eventBatchLimit)
        guard !events.isEmpty else {
            self.isDispatching = false
            self.startDispatchTimer()
            Logger.debug("Finished dispatching events")
            return
        }
        networking.send(events: events) { [weak self](result) in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                Logger.info(response.message)
                self.queue.remove(events: events)
                self.dispatchBatch()
            case .failure(let error):
                Logger.error(error.localizedDescription)
                self.isDispatching = false
                self.startDispatchTimer()
            }
        }
    }

}
