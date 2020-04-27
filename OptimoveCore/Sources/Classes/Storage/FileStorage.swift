//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public protocol FileStorage {

    /// Check file if exist.
    ///
    /// - Parameters:
    ///   - fileName: The file name on disk space.
    ///   - shared: set `true` if the requested file should be lookup in a shared container.
    /// - Returns: Return `true` if the requested file exist.
    func isExist(fileName: String, shared: Bool) -> Bool

    /// Save file.
    ///
    /// - Parameters:
    ///   - data: Data object that will be saved.
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

public final class FileStorageImpl {

    private struct Constants {
        static let folderName = "OptimoveSDK"
    }

    private let fileManager: FileManager
    private let groupedDirectoryURL: URL
    private let sharedDirectoryURL: URL

    public init(bundleIdentifier: String,
                fileManager: FileManager) throws {
        self.fileManager = fileManager

        groupedDirectoryURL = try fileManager.groupContainer(tenantBundleIdentifier: bundleIdentifier)
        sharedDirectoryURL = try unwrap(fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first)
    }

    private func addSkipBackupAttributeToItemAtURL(fileURL: URL) throws {
        var url = fileURL
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try url.setResourceValues(resourceValues)
    }

    private func getDirectory(shared: Bool) -> URL {
        let url = shared ? groupedDirectoryURL : sharedDirectoryURL
        return url.appendingPathComponent(Constants.folderName)
    }
}

extension FileStorageImpl: FileStorage {

    public func isExist(fileName: String, shared: Bool) -> Bool {
        let url = getDirectory(shared: shared)
        let fileUrl = url.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: fileUrl.path)
    }

    public func load(fileName: String, shared: Bool) throws -> Data {
        let fileUrl = getDirectory(shared: shared).appendingPathComponent(fileName)
        do {
            let contents = try unwrap(fileManager.contents(atPath: fileUrl.path))
            Logger.debug("Load file at \(fileName)")
            return contents
        } catch {
            Logger.error("Unable to load file \(fileName) at \(fileUrl.path). Reason: \(error.localizedDescription)")
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
            let url = getDirectory(shared: shared)
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            let fileURL = url.appendingPathComponent(fileName)
            let success = fileManager.createFile(atPath: fileURL.path, contents: data, attributes: nil)
            try addSkipBackupAttributeToItemAtURL(fileURL: fileURL)
            Logger.debug("File stored at \(fileName) successfull \(success.description).")
        } catch {
            Logger.error("Unable to store file \(fileName) failed. Reason: \(error.localizedDescription)")
            throw error
        }
    }

    public func delete(fileName: String, shared: Bool) throws {
        do {
            let fileUrl = getDirectory(shared: shared).appendingPathComponent(fileName)
            try fileManager.removeItem(at: fileUrl)
            Logger.debug("File deleted at \(fileUrl.absoluteString).")
        } catch {
            Logger.error("Unable to delete file \(fileName). Reason: \(error.localizedDescription)")
            throw error
        }
    }

}
