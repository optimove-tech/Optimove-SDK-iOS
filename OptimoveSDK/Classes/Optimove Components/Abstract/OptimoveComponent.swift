

import Foundation

class OptimoveComponent
{
    var isEnable = false
    
    var deviceStateMonitor:OptimoveDeviceStateMonitor
    
    init(deviceStateMonitor: OptimoveDeviceStateMonitor)
    {
        self.deviceStateMonitor = deviceStateMonitor
    }
    func performInitializationOperations(){}
}
