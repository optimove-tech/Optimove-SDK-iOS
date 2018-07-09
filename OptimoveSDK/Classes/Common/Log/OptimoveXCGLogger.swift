
import Foundation
import XCGLogger

@objc public class OptiLogger:NSObject
{
    private static let logger:XCGLogger = XCGLogger(identifier: "advancedLogger", includeDefaultDestinations: false)
    
    @objc public static func debug(_ message: String) {
        print(message)
        logger.debug(message)
    }
    @objc public static func error(_ message: String) {
        print(message)
        logger.error(message)
    }
    @objc public static func warning(_ message: String) {
        print(message)
        logger.warning(message)
    }
    @objc public static func severe(_ message: String) {
        print(message)
        logger.severe(message)
    }
    
    private override init() {}
    
     static func configure() {
       
        func manuallyManageLog(_ logUrl:URL) {
            var fileSize:UInt64
            do {
                let attr = try FileManager.default.attributesOfItem(atPath: logUrl.path)
                fileSize = attr[FileAttributeKey.size] as? UInt64 ?? 0
            }
            catch {
                fileSize = 0
            }
            if fileSize > 3000*1024
            {
                _ = try? FileManager.default.removeItem(at: logUrl)
            }
        }
        
        let logsUrl: URL = OptimoveFileManager.optimoveSDKDirectory.appendingPathComponent("Logs")
        
        // Create a file log destination
        if !FileManager.default.fileExists(atPath: logsUrl.path)
        {
            do {
                try FileManager.default.createDirectory(at: logsUrl, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                return
            }
        }
        let logUrl: URL = logsUrl.appendingPathComponent("Optimove_logger.txt")
        manuallyManageLog(logUrl)
        
        let fileDestination = FileDestination(owner: logger, writeToFile: logUrl, identifier: "advancedLogger.fileDestination", shouldAppend: true, appendMarker: "-- Relauched App --")
        // Optionally set some configuration options
        fileDestination.outputLevel = .debug
        fileDestination.showLogIdentifier = false
        fileDestination.showFunctionName = true
        fileDestination.showThreadName = true
        fileDestination.showLevel = true
        fileDestination.showFileName = true
        fileDestination.showLineNumber = true
        fileDestination.showDate = true
        
        fileDestination.logQueue = XCGLogger.logQueue
        
        // Add the destination to the logger
        logger.add(destination: fileDestination)
        
        let  autoRotatingFileDestination = AutoRotatingFileDestination(owner: nil,
                                                                       writeToFile: logUrl,
                                                                       identifier: "advancedLogger.fileDestination",
                                                                       shouldAppend: true,
                                                                       appendMarker: "**********************************",
                                                                       attributes: [:],
                                                                       maxFileSize: 1024 * 3072,
                                                                       maxTimeInterval: 600,
                                                                       archiveSuffixDateFormatter: nil)
        
        autoRotatingFileDestination.outputLevel = .verbose
        autoRotatingFileDestination.showLogIdentifier = false
        autoRotatingFileDestination.showFunctionName = true
        autoRotatingFileDestination.showThreadName = true
        autoRotatingFileDestination.showLevel = true
        autoRotatingFileDestination.showFileName = true
        autoRotatingFileDestination.showLineNumber = true
        autoRotatingFileDestination.showDate = true
        autoRotatingFileDestination.targetMaxLogFiles = 1
        autoRotatingFileDestination.logQueue = DispatchQueue.global(qos: .background)
        
        let ansiColorLogFormatter: ANSIColorLogFormatter = ANSIColorLogFormatter()
        ansiColorLogFormatter.colorize(level: .verbose, with: .colorIndex(number: 244), options: [.faint])
        ansiColorLogFormatter.colorize(level: .debug, with: .black)
        ansiColorLogFormatter.colorize(level: .info, with: .blue, options: [.underline])
        ansiColorLogFormatter.colorize(level: .warning, with: .red, options: [.faint])
        ansiColorLogFormatter.colorize(level: .error, with: .red, options: [.bold])
        ansiColorLogFormatter.colorize(level: .severe, with: .white, on: .red)
        autoRotatingFileDestination.formatters = [ansiColorLogFormatter]
        
        // Add the destination to the logger
        //        logger.add(destination: autoRotatingFileDestination)
        
        // Add basic app info, version info etc, to the start of the logs
        logger.logAppDetails()
    }
}
