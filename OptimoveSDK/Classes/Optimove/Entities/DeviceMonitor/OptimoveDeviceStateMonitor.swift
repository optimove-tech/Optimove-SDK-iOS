//  Copyright © 2019 Optimove. All rights reserved.

import UserNotifications
import OptimoveCore

public enum OptimoveDeviceRequirement: Int, CaseIterable, CustomStringConvertible {
    case internet = 0
    case advertisingId = 1
    case userNotification = 2

    static let userDependentPermissions: [OptimoveDeviceRequirement] = [.userNotification, .advertisingId]
    var isUserDependentPermissions: Bool {
        return OptimoveDeviceRequirement.userDependentPermissions.contains(self)
    }

    public var description: String {
        switch self {
        case .internet:
            return "Internet"
        case .advertisingId:
            return "AdvertisingId"
        case .userNotification:
            return "UserNotification"
        }
    }
}

protocol OptimoveDeviceStateMonitor {

    func getStatus(for: OptimoveDeviceRequirement, completion: @escaping ResultBlockWithBool)

}

final class OptimoveDeviceStateMonitorImpl {

    private let accessQueue: DispatchQueue
    private let fetcherFactory: DeviceRequirementFetcherFactory
    private var fetchers: [OptimoveDeviceRequirement: Fetchable] = [:]
    private var statuses: [OptimoveDeviceRequirement: Bool] = [:]
    private var requests: [OptimoveDeviceRequirement: [ResultBlockWithBool]]

    init(fetcherFactory: DeviceRequirementFetcherFactory) {
        self.fetcherFactory = fetcherFactory
        accessQueue = DispatchQueue(label: "com.optimove.sdk.queue.deviceState", qos: .utility)
        requests = OptimoveDeviceRequirement.allCases.reduce(into: [:], { (result, next) in
            result[next] = []
        })
    }
}

extension OptimoveDeviceStateMonitorImpl: OptimoveDeviceStateMonitor {

    func getStatus(for deviceRequirement: OptimoveDeviceRequirement, completion: @escaping ResultBlockWithBool) {
        accessQueue.async { [weak self] in
            if let status = self?.statuses[deviceRequirement] {
                completion(status)
                return
            }
            self?.requestStatus(for: deviceRequirement, completion: completion)
        }
    }
}

private extension OptimoveDeviceStateMonitorImpl {

    func requestStatus(for requiredService: OptimoveDeviceRequirement, completion: @escaping ResultBlockWithBool) {
        Logger.debug("Status for Device requirement '\(requiredService.description)' enqueued.")
        requests[requiredService]?.append(completion)
        let fetcher = getFetcher(for: requiredService)
        fetcher.fetch { [weak self] (status) in
            self?.accessQueue.async {
                Logger.info("Device requirement \(requiredService.description) has status: \(status)")
                self?.handleFetcherResult(deviceRequirement: requiredService, status: status)
            }
        }
    }

    func handleFetcherResult(deviceRequirement: OptimoveDeviceRequirement, status: Bool) {
        statuses[deviceRequirement] = status
        requests[deviceRequirement]?.forEach { $0(status) }
        requests[deviceRequirement]?.removeAll()
    }

    func getFetcher(for requirement: OptimoveDeviceRequirement) -> Fetchable {
        if let fetcher = fetchers[requirement] {
            return fetcher
        }
        let fetcher = fetcherFactory.createFetcher(for: requirement)
        fetchers[requirement] = fetcher
        return fetcher
    }

}
