//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

typealias OptistreamEvent = OptimoveCore.OptistreamEvent
typealias OptistreamEventBuilder = OptimoveCore.OptistreamEventBuilder
typealias OptistreamNetworking = OptimoveCore.OptistreamNetworking

final class OptiTrack {

    private struct Constants {
        static let eventBatchLimit = 100
        static let queueLabel = "com.optimove.track"
    }

    var dispatchInterval: TimeInterval = 30.0 {
        didSet {
            startDispatchTimer()
        }
    }

    private let queue: OptistreamQueue
    private let optirstreamEventBuilder: OptistreamEventBuilder
    private let networking: OptistreamNetworking
    private var isDispatching = false

    private var dispatchTimer: Timer?
    private let dispatchQueue = DispatchQueue(label: Constants.queueLabel)

    init(queue: OptistreamQueue,
         optirstreamEventBuilder: OptistreamEventBuilder,
         networking: OptistreamNetworking) {
        self.queue = queue
        self.optirstreamEventBuilder = optirstreamEventBuilder
        self.networking = networking
        startDispatchTimer()
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

    func startDispatchTimer() {
        guard isTrackQueue() else {
            dispatchQueue.async {
                self.startDispatchTimer()
            }
            return
        }
        guard dispatchInterval > 0  else { return }
        if let dispatchTimer = dispatchTimer {
            dispatchTimer.invalidate()
            self.dispatchTimer = nil
        }
        dispatchQueue.async { [weak self] in
            guard let self = self else { return }
            let currentRunLoop = RunLoop.current
            self.dispatchTimer = Timer(
                timeInterval: self.dispatchInterval,
                target: self,
                selector: #selector(self.dispatch),
                userInfo: nil,
                repeats: false
            )
            currentRunLoop.add(self.dispatchTimer!, forMode: .common)
            currentRunLoop.run()
        }
    }

    func isTrackQueue() -> Bool {
        guard String(cString: __dispatch_queue_get_label(nil), encoding: .utf8) == Constants.queueLabel else {
            return false
        }
        return true
    }

    func track(event: Event) {
        tryCatch {
            let streamEvent = try optirstreamEventBuilder.build(event: event)
            dispatchQueue.async {
                self.queue.enqueue(events: [streamEvent])
                if event.isRealtime {
                    self.dispatch()
                }
            }
        }
    }

    @objc func dispatch() {
        guard isTrackQueue() else {
            dispatchQueue.async {
                self.dispatch()
            }
            return
        }
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

    func dispatchBatch() {
        guard isTrackQueue() else {
            dispatchQueue.async {
                self.dispatchBatch()
            }
            return
        }
        let events = queue.first(limit: Constants.eventBatchLimit)
        guard !events.isEmpty else {
            self.isDispatching = false
            self.startDispatchTimer()
            Logger.debug("Finished dispatching events")
            return
        }
        networking.send(events: events) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                self.dispatchQueue.async {
                    Logger.info(response.message)
                    self.queue.remove(events: events)
                    self.dispatchBatch()
                }
            case .failure(let error):
                self.dispatchQueue.async {
                    Logger.error(error.localizedDescription)
                    self.isDispatching = false
                    self.startDispatchTimer()
                }
            }
        }
    }

}
