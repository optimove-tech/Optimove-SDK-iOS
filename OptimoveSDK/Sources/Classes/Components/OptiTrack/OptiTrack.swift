//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

typealias OptistreamEvent = OptimoveCore.OptistreamEvent
typealias OptistreamEventBuilder = OptimoveCore.OptistreamEventBuilder
typealias OptistreamNetworking = OptimoveCore.OptistreamNetworking

final class OptiTrack {

    private struct Constants {
        static let eventBatchLimit = 50
        static let queueLabel = "com.optimove.track"
    }

    var dispatchInterval: TimeInterval = 30 {
        didSet {
            startDispatchTimer()
        }
    }

    private let queue: OptistreamQueue
    private let networking: OptistreamNetworking
    private let configuration: OptitrackConfig
    private var isDispatching = false
    private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
    private var dispatchTimer: Timer?
    private let dispatchQueue = DispatchQueue(label: Constants.queueLabel)

    init(
        queue: OptistreamQueue,
        networking: OptistreamNetworking,
        configuration: OptitrackConfig
    ) {
        self.queue = queue
        self.networking = networking
        self.configuration = configuration
        startDispatchTimer()
    }

    private func startBackgroundTask() {
        backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "Dispatch now") {
            self.stopBackgroundTask()
        }
    }

    private func stopBackgroundTask() {
        guard self.backgroundTaskId != .invalid else { return }
        UIApplication.shared.endBackgroundTask(self.backgroundTaskId)
        self.backgroundTaskId = .invalid
    }
}

extension OptiTrack: OptistreamComponent {

    func handle(_ operation: OptistreamOperation) throws {
        switch operation {
        case let .report(events: events):
            track(events: events)
        case .dispatchNow:
            startBackgroundTask()
            dispatch()
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

    func track(events: [OptistreamEvent]) {
        dispatchQueue.async { [weak self] in
            guard let self = self else { return }
            let events = events.map(self.applyRealtimeMutation)
            self.queue.enqueue(events: events)
            if events.map(self.shouldDispatchNow).contains(true) {
                self.dispatch()
            }
        }
    }

    func applyRealtimeMutation(_ event: OptistreamEvent) -> OptistreamEvent {
        var event = event
        event.metadata.realtime = event.metadata.realtime && configuration.isEnableRealtime
        return event
    }

    func shouldDispatchNow(_ event: OptistreamEvent) -> Bool {
        return event.metadata.realtime
    }

    @objc func dispatch() {
        guard isTrackQueue() else {
            dispatchQueue.async {
                self.dispatch()
            }
            return
        }
        guard !isDispatching else {
            stopBackgroundTask()
            Logger.debug("Tracker is already dispatching.")
            return
        }
        guard !queue.isEmpty else {
            Logger.debug("No need to dispatch. Dispatch queue is empty.")
            startDispatchTimer()
            stopBackgroundTask()
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
            stopBackgroundTask()
            Logger.debug("Finished dispatching events")
            return
        }
        networking.send(events: events) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success:
                self.dispatchQueue.async {
                    self.queue.remove(events: events)
                    self.dispatchBatch()
                }
            case .failure(let error):
                self.dispatchQueue.async {
                    Logger.error(error.localizedDescription)
                    self.isDispatching = false
                    switch error {
                    case .requestInvalid:
                        self.queue.remove(events: events)
                    default:
                        break
                    }
                    self.startDispatchTimer()
                    self.stopBackgroundTask()
                }
            }
        }
    }

}
