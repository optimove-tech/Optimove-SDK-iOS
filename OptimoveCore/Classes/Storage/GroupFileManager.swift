//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public protocol FileStorage {

    /// Check file if exist.
    ///
    /// - Parameters:
    ///   - fileName: The file name on disk space.
    ///   - shared: set `true` if the requested file should be lookup in a shared container.
    /// - Returns: Return `true` if the requested file exist.
    func isExist(fileName: String, shared: Bool) throws -> Bool

    /// Save file.
    ///
    /// - Parameters:
    ///   - data: Encodable object that will be saved.
    ///   - toFileName: The file name on disk space.
    ///   - shared: set `true` if the file should be save a shared container.
    func save<T: Encodable>(data: T, toFileName: String, shared: Bool) throws

    /// Save file.
    ///
    /// - Parameters:
    ///   - data: Raw data
    ///   - toFileName: The file name on disk space.
    ///   - shared: set `true` if the file should be save a shared container.
    func saveData(data: Data, toFileName: String, shared: Bool) throws

    /// Load file.
    ///
    /// - Parameters:
    ///   - fileName: The file name on disk space.
    ///   - shared: set `true` if the requested file should be lookup in a shared container.
    /// - Returns: Return `Data` if file will be found, or `nil` if not.
    func load(fileName: String, shared: Bool) throws -> Data

    /// Delete file.
    ///
    /// - Parameters:
    ///   - fileName: The file name on disk space.
    ///   - shared: set `true` if the requested file should be deleted in a shared container.
    func delete(fileName: String, shared: Bool) throws

}

public final class GroupedFileManager {

    private struct Constants {
        static let folderName = "OptimoveSDK"
    }

    private let fileManager: FileManager
    private lazy var groupedDirectoryURL: URL? = {
        let bundleIdentifier = Bundle.main.bundleIdentifier!
        let groupIdentifier = "group.\(bundleIdentifier).optimove"
        return fileManager.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier)
    }()
    private lazy var sharedDirectoryURL: URL? = {
        return fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }()

    public init(fileManager: FileManager) {
        self.fileManager = fileManager
    }

    private func addSkipBackupAttributeToItemAtURL(fileURL: URL) throws {
        var url = fileURL
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try url.setResourceValues(resourceValues)
    }

    private func getDirectory(shared: Bool) throws -> URL {
        let groupURL: URL? = {
            if shared {
                return groupedDirectoryURL
            }
            return sharedDirectoryURL
        }()
        guard let url = groupURL else {
            fatalError("""
To enable OptiPush, check adding an `App group` capability in both the app and the extension targets.
The group name convention should be: `group.<bundleIdentifier>.optimove`
""")
        }
        return url.appendingPathComponent(Constants.folderName)
    }
}

extension GroupedFileManager: FileStorage {

    public func isExist(fileName: String, shared: Bool) throws -> Bool {
        let url = try getDirectory(shared: shared)
        let fileUrl = url.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: fileUrl.path)
    }

    public func load(fileName: String, shared: Bool) throws -> Data {
        let fileUrl = try getDirectory(shared: shared)
            .appendingPathComponent(fileName)
        do {
            let contents = try Data.init(contentsOf: fileUrl)
//            OptiLoggerMessages.logLoadFile(fileUrl: fileUrl.path)
            return contents
        } catch {
//            OptiLoggerMessages.logLoadFileFailure(name: fileName)
//            OptiLoggerMessages.logError(error: error)
            throw error
        }
    }

    public func save<T: Encodable>(
        data: T,
        toFileName fileName: String,
        shared: Bool = false) throws {
        let data = try JSONEncoder().encode(data)
        try saveData(data: data, toFileName: fileName, shared: shared)
    }

    public func saveData(
        data: Data,
        toFileName fileName: String,
        shared: Bool = false) throws {
        do {
            let url = try getDirectory(shared: shared)
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            let fileURL = url.appendingPathComponent(fileName)
            let success = fileManager.createFile(atPath: fileURL.path, contents: data, attributes: nil)
            try addSkipBackupAttributeToItemAtURL(fileURL: fileURL)
//            OptiLoggerMessages.logStoringFileStatus(
//                name: fileName,
//                successStatus: success.description,
//                fileLocation: url.path
//            )
        } catch {
//            OptiLoggerMessages.logStringFailureStatus(name: fileName)
            throw error
        }
    }

    public func delete(fileName: String, shared: Bool) throws {
        do {
            let fileUrl = try getDirectory(shared: shared).appendingPathComponent(fileName)
            try fileManager.removeItem(at: fileUrl)
//            OptiLoggerMessages.logDeleteFile(name: fileName)
        } catch {
//            OptiLoggerMessages.logFileDeletionFailure(name: fileName)
//            OptiLoggerMessages.logError(error: error)
            throw error
        }
    }

}
