//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

extension Event {

    private struct Constants {
        struct Key {
            static let eventDeviceType = "event_device_type"
            static let eventPlatform = "event_platform"
            static let eventOs = "event_os"
            static let eventNativeMobile = "event_native_mobile"
        }
        struct Value {
            static let eventDeviceType = "Mobile"
            static let eventPlatform = "iOS"
            static let eventOs = "iOS \(operatingSystemVersionOnlyString)"
            static let eventNativeMobile = true
            private static let operatingSystemVersionOnlyString = ProcessInfo().operatingSystemVersionOnlyString

        }
    }

    func decorate(config: EventsConfig) -> Event {
        if config.parameters[Constants.Key.eventDeviceType] != nil {
            self.context[Constants.Key.eventDeviceType] = Constants.Value.eventDeviceType
        }
        if config.parameters[Constants.Key.eventNativeMobile] != nil {
            self.context[Constants.Key.eventNativeMobile] = Constants.Value.eventNativeMobile
        }
        if config.parameters[Constants.Key.eventOs] != nil {
            self.context[Constants.Key.eventOs] = Constants.Value.eventOs
        }
        if config.parameters[Constants.Key.eventPlatform] != nil {
            self.context[Constants.Key.eventPlatform] = Constants.Value.eventPlatform
        }
        self.isRealtime = config.supportedOnRealTime
        return self
    }

}
