import Foundation

enum MbaasOperations: String, Codable {
    case registration = "registration_data"
    case unregistration = "unregistration_data"
    case optOut = "opt_out"
    case optIn = "opt_in"
}
