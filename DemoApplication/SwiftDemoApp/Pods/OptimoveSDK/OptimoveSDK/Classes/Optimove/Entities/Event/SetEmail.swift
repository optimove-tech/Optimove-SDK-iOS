

import Foundation
class SetEmailEvent: OptimoveCoreEvent
{
    let email:String
    init(email:String) {
        self.email = email
    }
    var name: String {
        return  "Set_email_event"
    }
    
    var parameters: [String : Any] {
        return ["email":email]
    }
    
    
}
