import UserNotifications

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
    
    func getStatuses(for: [OptimoveDeviceRequirement], completion: @escaping ([OptimoveDeviceRequirement: Bool]) -> Void)
    
    /// - Warning: Returning cached results.
    /// - ToDo: Change to `getMissingPermissions(completion: @escaping (Result<[OptimoveDeviceRequirement], Error> -> Void))`.
    func getMissingPermissions() -> [OptimoveDeviceRequirement]
}

final class OptimoveDeviceStateMonitorImpl {
    
    private let accessQueue: DispatchQueue
    private let fetcherFactory: DeviceRequirementFetcherFactory
    private var fetchers: [OptimoveDeviceRequirement: Fetchable] = [:]
    private var statuses: [OptimoveDeviceRequirement: Bool] = [:]
    private var requests: [OptimoveDeviceRequirement: [ResultBlockWithBool]]
    
    init(fetcherFactory: DeviceRequirementFetcherFactory) {
        self.fetcherFactory = fetcherFactory
        accessQueue = DispatchQueue(label: "com.optimove.sdk.queue.deviceState", qos: .background)
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
    
    func getStatuses(for requirements: [OptimoveDeviceRequirement], completion: @escaping ([OptimoveDeviceRequirement: Bool]) -> Void) {
        let group = DispatchGroup()
        DispatchQueue.global(qos: .background).async {
            requirements.forEach { (requirement) in
                group.enter()
                self.getStatus(for: requirement) { _ in
                    group.leave()
                }
            }
        }
        group.notify(queue: accessQueue) {
            let statuses = self.statuses
            completion(statuses)
        }
    }
    
    func getMissingPermissions() -> [OptimoveDeviceRequirement] {
        return accessQueue.sync {
            return statuses
                .filter { $0.value == false }
                .compactMap { $0.key.isUserDependentPermissions ? $0.key : nil }
        }
    }
}

private extension OptimoveDeviceStateMonitorImpl {
    
    func requestStatus(for requiredService: OptimoveDeviceRequirement, completion: @escaping ResultBlockWithBool) {
        OptiLoggerMessages.logDeviceRequirementNil(requiredService: requiredService)
        OptiLoggerMessages.logRegisterToReceiveRequirementStatus(requiredService: requiredService)
        requests[requiredService]?.append(completion)
        OptiLoggerMessages.logGetStatusOf(requiredService: requiredService)
        let fetcher = getFetcher(for: requiredService)
        fetcher.fetch { [weak self] (status) in
            self?.accessQueue.async {
                OptiLoggerMessages.logRequirementtatus(deviceRequirement: requiredService, status: status)
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
