import Foundation
class SetEmailEvent: OptimoveCoreEvent {
    let email: String
    var name: String {
        return  OptimoveKeys.Configuration.setEmail.rawValue
    }

    var parameters: [String: Any]

    init(email: String) {
        self.email = email
        self.parameters = ["email": email]
    }
}
