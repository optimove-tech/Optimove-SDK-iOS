

import UIKit
import OptimoveSDK


class EventTableViewCell: UITableViewCell {

    var customEventType: CustomEventType!
    var callback: ResultBlockWithError!
    
    @IBOutlet weak var eventTypeLabel: UILabel!
    @IBOutlet weak var numberInputTextField: UITextField!
    @IBOutlet weak var stringInputTextField: UITextField!

    func setup(_ customEventType: CustomEventType)
    {
        
        self.customEventType = customEventType
        
        switch customEventType {
        case .string:
            eventTypeLabel.text = "String Event"
        case .number:
            eventTypeLabel.text = "Number Event"
        case .combined:
            eventTypeLabel.text = "Combined Event"
        }
    }
    
    @IBAction func sendEvent(_ sender: UIButton)
    {
        let isEmptyString = stringInputTextField.text?.isEmpty ?? true
        let isEmptyNumber = numberInputTextField.text?.isEmpty ?? true
        
        let stringInput: String? = isEmptyString ? nil : stringInputTextField.text
        let numberInput: Double? = isEmptyNumber ? nil : Double.init(numberInputTextField.text!)
        
        var event: OptimoveEvent
        switch customEventType
        {
        case .string?:
            event = StringEvent(stringInput)
        case .number?:
            event = NumberEvent(numberInput != nil ? NSNumber(value:numberInput!): nil)
        case .combined?:
            event = CombinedEvent(stringInput, numberInput != nil ? NSNumber(value:numberInput!): nil)
        default: return
        }
        Optimove.shared.reportEvent(event)
        
    }
}

