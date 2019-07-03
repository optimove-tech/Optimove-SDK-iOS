import Foundation

class OptiLoggerConsoleStream: NSObject, OptiLoggerOutputStream {

    func log(level: LogLevel, fileName: String, methodName: String, logModule: String?, message: String) {
        optiLog(level: level, fileName: fileName, methodName: methodName, logModule: logModule, message: message)
    }

    var isVisibleToClient: Bool {
        return true
    }

    private func optiLog(level: LogLevel, fileName: String, methodName: String, logModule: String?, message: String) {
        print("OptimoveSDK-\(level.name)/\(fileName):\(methodName) \(message)")
    }
}
