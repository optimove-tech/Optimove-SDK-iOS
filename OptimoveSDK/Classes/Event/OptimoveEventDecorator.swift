
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
            case OptimoveKeys.AdditionalAttributesKeys.eventDeviceType:
                params[OptimoveKeys.AdditionalAttributesKeys.eventDeviceType] = OptimoveKeys.AddtionalAttributesValues.eventDeviceType
            case OptimoveKeys.AdditionalAttributesKeys.eventNativeMobile:
                params[OptimoveKeys.AdditionalAttributesKeys.eventNativeMobile] = OptimoveKeys.AddtionalAttributesValues.eventNativeMobile
            case OptimoveKeys.AdditionalAttributesKeys.eventOs:
                params[OptimoveKeys.AdditionalAttributesKeys.eventOs] = OptimoveKeys.AddtionalAttributesValues.eventOs
            case OptimoveKeys.AdditionalAttributesKeys.eventPlatform:
                params[OptimoveKeys.AdditionalAttributesKeys.eventPlatform] = OptimoveKeys.AddtionalAttributesValues.eventPlatform
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
