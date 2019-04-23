import Foundation

protocol OptimoveComponentInitializationProtocol {
	associatedtype T: OptimoveComponent
	init(component: T)

	func setEnabled(from tenantConfig: TenantConfig)
	func getRequirements() -> [OptimoveDeviceRequirement]
	func executeInternalConfigurationLogic(from tenantConfig: TenantConfig, didComplete: @escaping ResultBlockWithBool)
}

class OptimoveComponentConfigurator<T: OptimoveComponent>: OptimoveComponentInitializationProtocol {
	let component: T

	required init(component: T) {
		self.component = component
	}

    func configure(from tenantConfig: TenantConfig, didComplete: @escaping ResultBlockWithBool) {
        setEnabled(from: tenantConfig)

        let requirements = getRequirements()
        component.deviceStateMonitor.getStatus(of: requirements) { _ in
            DispatchQueue.main.async {
                self.executeInternalConfigurationLogic(from: tenantConfig, didComplete: didComplete)
                self.component.performInitializationOperations()
            }
        }
    }

    func setEnabled(from tenantConfig: TenantConfig) {
		fatalError("Not Implemented")
	}

	func getRequirements() -> [OptimoveDeviceRequirement] {
		fatalError("Not Implemented")
	}

	func executeInternalConfigurationLogic(from tenantConfig: TenantConfig, didComplete: @escaping ResultBlockWithBool) {
		fatalError("Not Implemented")
	}

}
