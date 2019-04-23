@objc public protocol OptiLoggerOutputStream: AnyObject {
    func log(level:LogLevel,fileName: String, methodName: String, logModule:String?, message: String)
    var isVisibleToClient: Bool { get }
}
