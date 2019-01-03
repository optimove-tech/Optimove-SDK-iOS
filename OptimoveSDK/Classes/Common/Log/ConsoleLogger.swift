//import Foundation
class OptiConsoleLog: NSObject,OptiLoggerOutputStream {
    func debug(tag: String, message: String, args: [String]) {
        optiLog(tag: tag, message: message, args: args)
    }

    func info(tag: String, message: String, args: [String]) {
        optiLog(tag: tag, message: message, args: args)
    }

    func warning(tag: String, message: String, args: [String]) {
        optiLog(tag: tag, message: message, args: args)
    }

    func error(tag: String, message: String, args: [String]) {
        optiLog(tag: tag, message: message, args: args)
    }

    func fatal(tag: String, message: String, args: [String]) {
        optiLog(tag: tag, message: message, args: args)
    }



    private func optiLog(tag: String, message: String, args: [String]) {
        let arguments = args.joined(separator: ":")
        print("\(tag):\(arguments) \(message)")
    }
}
