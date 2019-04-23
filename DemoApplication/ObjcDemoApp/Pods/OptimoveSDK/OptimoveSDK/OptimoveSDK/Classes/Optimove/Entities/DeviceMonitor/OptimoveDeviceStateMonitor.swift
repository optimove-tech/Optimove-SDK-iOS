import UserNotifications

@objc public enum OptimoveDeviceRequirement: Int {
    case internet           = 0
    case advertisingId      = 1
    case userNotification   = 2

    static let userDependentPermissions: [OptimoveDeviceRequirement] = [.userNotification, .advertisingId]
}

class OptimoveDeviceStateMonitor {
    private var deviceRequirementStatuses: [OptimoveDeviceRequirement: Bool] = [:]

    private var deviceRequirementRequests: [OptimoveDeviceRequirement: [ResultBlockWithBool]] = [:] //cache any request from client

    func getStatus(of requiredService: OptimoveDeviceRequirement, completionHandler: @escaping ResultBlockWithBool) {
        guard let status = deviceRequirementStatuses[requiredService] else {
            OptiLoggerMessages.logDeviceRequirementNil(requiredService: requiredService)
            OptiLoggerMessages.logRegisterToReceiveRequirementStatus(requiredService: requiredService)
            if deviceRequirementRequests[requiredService] == nil {
                deviceRequirementRequests[requiredService] = [completionHandler]
            } else {
                deviceRequirementRequests[requiredService]?.append(completionHandler)
            }
            OptiLoggerMessages.logGetStatusOf(requiredService: requiredService)
            getStatusFromFetcher(deviceRequirement: requiredService)
            return
        }
        completionHandler(status)
    }

    func getStatus(of deviceRequirements: [OptimoveDeviceRequirement],
                   completionHandler: @escaping ([OptimoveDeviceRequirement: Bool]) -> Void ) {
        var result = [OptimoveDeviceRequirement: Bool]()
        deviceRequirements.forEach { (req) in
            getStatus(of: req) { (status) in
                result[req] = status
                self.deviceRequirementStatuses[req] = status

                //TODO: Check Thread Safety
                // first aid for not having request management system
                if result.count == deviceRequirements.count {
                    completionHandler(result)
                }
            }
        }
    }

    private func getStatusFromFetcher(deviceRequirement: OptimoveDeviceRequirement) {
        DeviceReuirementFetcherFactory.getInstance(requirement: deviceRequirement).fetch {(status) in
            OptiLoggerMessages.logRequirementtatus(deviceRequirement: deviceRequirement, status: status)
            self.deviceRequirementStatuses[deviceRequirement] = status
            self.deviceRequirementRequests[deviceRequirement]?.forEach { resultBlock in
                resultBlock(status)
            }
            self.deviceRequirementRequests[deviceRequirement] = nil
        }
    }

    func getMissingPermissions() -> [OptimoveDeviceRequirement] {
        var result: [OptimoveDeviceRequirement] = []
        for (requirement, status) in deviceRequirementStatuses {
            if status { continue }
            if OptimoveDeviceRequirement.userDependentPermissions.contains(requirement) {
                result.append(requirement)
            }
        }
        return result
    }

    @objc func getMissingPersmissions() -> [Int] {
        var result: [Int] = []
        for (requirement, status) in deviceRequirementStatuses {
            if status { continue }
            if OptimoveDeviceRequirement.userDependentPermissions.contains(requirement) {
                result.append(requirement.rawValue)
            }
        }
        return result
    }
}
