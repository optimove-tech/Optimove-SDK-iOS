import OptimoveCore

class SimpleCustomEvent: OptimoveEvent {
    var name: String
    var parameters: [String: Any]

    init(name: String, parameters: [String: Any] = [:]) {
        self.name = name
        self.parameters = parameters
    }

}
