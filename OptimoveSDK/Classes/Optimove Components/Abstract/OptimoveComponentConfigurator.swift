import Foundation

protocol OptimoveComponentInitializationProtocol {
    associatedtype T: OptimoveComponent
    init(component: T)

    func getRequirements() -> [OptimoveDeviceRequirement]
    func executeInternalConfigurationLogic(from tenantConfig: TenantConfig, didComplete: @escaping ResultBlockWithBool)
}

class OptimoveComponentConfigurator<T: OptimoveComponent>: OptimoveComponentInitializationProtocol {
    let component: T

    required init(component: T) {
        self.component = component
    }

    func configure(from tenantConfig: TenantConfig, didComplete: @escaping ResultBlockWithBool) {

        let requirements = getRequirements()
        // TODO: Remove deprecated method and be off from the Main thread.
        component.deviceStateMonitor.getStatuses(for: requirements) { _ in
            DispatchQueue.main.async {
                self.executeInternalConfigurationLogic(from: tenantConfig, didComplete: didComplete)
                self.component.performInitializationOperations()
            }
        }
    }

    func getRequirements() -> [OptimoveDeviceRequirement] {
        fatalError("Not Implemented")
    }

    func executeInternalConfigurationLogic(from tenantConfig: TenantConfig, didComplete: @escaping ResultBlockWithBool)
    {
        fatalError("Not Implemented")
    }

}
