
import Foundation
class OptimoveEventDecorator:OptimoveEvent
{
    private let event:OptimoveEvent
    private let config:OptimoveEventConfig
    init(event:OptimoveEvent,config:OptimoveEventConfig)
    {
        self.event = event
        self.config = config
    }
    var name: String {
        return event.name
    }
    var parameters: [String : Any] {
        var params = event.parameters
        for parameter in config.parameters {
            switch parameter.key
            {
            case Keys.AdditionalAttributesKeys.eventDeviceType:
                params[Keys.AdditionalAttributesKeys.eventDeviceType] = Keys.AddtionalAttributesValues.eventDeviceType
            case Keys.AdditionalAttributesKeys.eventNativeMobile:
                params[Keys.AdditionalAttributesKeys.eventNativeMobile] = Keys.AddtionalAttributesValues.eventNativeMobile
            case Keys.AdditionalAttributesKeys.eventOs:
                params[Keys.AdditionalAttributesKeys.eventOs] = Keys.AddtionalAttributesValues.eventOs
            case Keys.AdditionalAttributesKeys.eventPlatform:
                params[Keys.AdditionalAttributesKeys.eventPlatform] = Keys.AddtionalAttributesValues.eventPlatform
            default:
                continue
            }
        }
        return params
    }
    var isOptimoveCoreEvent:Bool {
        return self.event is OptimoveCoreEvent
    }
}
