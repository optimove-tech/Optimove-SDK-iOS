import Foundation

enum OptimoveSdkCommand: RawRepresentable {
    init?(rawValue: String) {
        switch rawValue {
        case "ping": self = .ping
        case "reregister": self = .reregister
        default: return nil
        }
    }

    var rawValue: String {
        switch self {
        case .ping: return "ping"
        case .reregister: return "reregister"
        }
    }

    typealias RawValue = String

    case ping
    case reregister
}
