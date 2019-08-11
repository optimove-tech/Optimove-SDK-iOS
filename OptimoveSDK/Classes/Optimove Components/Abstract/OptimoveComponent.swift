import Foundation

class OptimoveComponent {

    var deviceStateMonitor: OptimoveDeviceStateMonitor

    init(deviceStateMonitor: OptimoveDeviceStateMonitor) {
        self.deviceStateMonitor = deviceStateMonitor
    }
    
    /// Do nothing.
    func performInitializationOperations() {}
}
