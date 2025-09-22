//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore
import UIKit

typealias OptistreamEvent = OptimoveCore.OptistreamEvent
typealias OptistreamEventBuilder = OptimoveCore.OptistreamEventBuilder
typealias OptistreamNetworking = OptimoveCore.OptistreamNetworking

final class OptiTrack {
    enum Constants {
        static let eventBatchLimit = 50
    }

    var dispatchInterval: TimeInterval = 10 {
        didSet {
            startDispatchTimer()
        }
    }

    private let queue: OptistreamQueue
    private let networking: OptistreamNetworking
    private let configuration: OptitrackConfig
    private var backgroundTaskId: UIBackgroundTaskIdentifier = .invalid
    private var dispatchTimer: Timer?
    private let dispatchQueue = DispatchQueue(label: "com.optimove.track", qos: .userInitiated)

    private var isDispatching = false

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

    deinit {
        stopDispatchTimer()
    }

    private func startBackgroundTask() {
        stopBackgroundTask()
        backgroundTaskId = UIApplication.shared.beginBackgroundTask(withName: "Dispatch now") { [weak self] in
            self?.stopBackgroundTask()
        }
    }

    private func stopBackgroundTask() {
        guard backgroundTaskId != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTaskId)
        backgroundTaskId = .invalid
    }
}

extension OptiTrack: OptistreamComponent {
    func serve(_ operation: OptistreamOperation) throws {
        Logger.debug("\(self) serve \(operation)")
        dispatchQueue.async { [weak self] in
            guard let self = self else { return }
            switch operation {
            case let .report(events: events):
                let events = events.map(self.applyRealtimeMutation)
                self.queue.enqueue(events: events)
                if events.map(self.shouldDispatchNow).contains(true) {
                    self.dispatch()
                }
            case .dispatchNow:
                self.startBackgroundTask()
                self.dispatch()
            }
        }
    }
}

private extension OptiTrack {
    func startDispatchTimer() {
        guard Thread.isMainThread else {
            DispatchQueue.main.sync {
                self.startDispatchTimer()
            }
            return
        }
        guard dispatchInterval > 0 else { return }
        stopDispatchTimer()
        /// Dispatching asynchronous to break the retain cycle
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let timer = Timer.scheduledTimer(
                timeInterval: self.dispatchInterval,
                target: self,
                selector: #selector(self.dispatch),
                userInfo: nil,
                repeats: false
            )
            timer.tolerance = 0.2
            RunLoop.main.add(timer, forMode: RunLoop.Mode.common)
            self.dispatchTimer = timer
        }
    }

    func stopDispatchTimer() {
        guard Thread.isMainThread else {
            DispatchQueue.main.sync {
                self.startDispatchTimer()
            }
            return
        }
        if let dispatchTimer = dispatchTimer {
            dispatchTimer.invalidate()
            self.dispatchTimer = nil
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
        guard !Thread.isMainThread else {
            dispatchQueue.async {
                self.dispatch()
            }
            return
        }
        guard !isDispatching else {
            Logger.debug("Tracker is already dispatching.")
            return
        }
        guard !queue.isEmpty else {
            Logger.debug("No need to dispatch. Dispatch queue is empty.")
            stopDispatching()
            return
        }
        Logger.info("Start dispatching events")
        isDispatching = true
        dispatchBatch()
    }

    func dispatchBatch() {
        let events = queue.first(limit: Constants.eventBatchLimit)
        guard !events.isEmpty else {
            stopDispatching()
            Logger.info("Finished dispatching events")
            return
        }
        networking.send(events: events) { [weak self] result in
            guard let self = self else { return }
            self.dispatchQueue.async {
                switch result {
                case .success:
                    self.queue.remove(events: events)
                    self.dispatchBatch()
                case let .failure(error):
                    Logger.error(error.localizedDescription)
                    switch error {
                    case .requestInvalid:
                        self.queue.remove(events: events)
                    default:
                        break
                    }
                    self.stopDispatching()
                }
            }
        }
    }

    func stopDispatching() {
        isDispatching = false
        stopBackgroundTask()
        startDispatchTimer()
    }
}
