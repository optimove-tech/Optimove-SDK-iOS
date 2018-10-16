

import Foundation
class SetEmailEvent: OptimoveCoreEvent
{
    let email:String
    var name: String {
        return  "set_email_event"
    }

    var parameters: [String : Any]

    init(email:String) {
        self.email = email
        self.parameters = ["email":email]
    }
}
