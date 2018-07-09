

import Foundation
import OptimoveSDK

class StringEvent: OptimoveEvent
{
    
    var input: String?
    
    init(_ input: String? = nil)
    {
        self.input = input
    }
    
    var name: String
    {
        return "custom_string_event"
    }
    
    var parameters: [String : Any]
    {
        if let input = input
        {
            return ["string_param": input]
        }
        return [:]
    }
}

class NumberEvent:OptimoveEvent
{
    var input: NSNumber?
    
    init(_ input: NSNumber? = nil)
    {
        self.input = input
    }
    
    var name: String
    {
        return "custom_number_event"
    }
    
    var parameters: [String : Any]
    {
        if let input = input
        {
            return ["number_param": input]
        }
        return [:]
    }
}

class CombinedEvent:OptimoveEvent
{
    var stringInput: String?
    var numberInput: NSNumber?

    init(_ stringInput: String? = nil, _ numberInput: NSNumber? = nil)
    {
        self.stringInput = stringInput
        self.numberInput = numberInput
    }
    
    var name: String
    {
        return "custom_combined_event"
    }
    
    var parameters: [String : Any]
    {
        if let stringInput = stringInput, let numberInput = numberInput
        {
            return ["string_param": stringInput,
                    "number_param": numberInput ]
        }

        if let stringInput = stringInput
        {
            return ["string_param": stringInput]
        }
        
        if let numberInput = numberInput
        {
            return ["number_param": numberInput]
        }
        return [:]
    }
}

enum CustomEventType {
    case string, number, combined
}
