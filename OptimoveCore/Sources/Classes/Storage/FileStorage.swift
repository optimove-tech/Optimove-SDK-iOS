//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public protocol FileStorage {
    /// Check file if exist.
    ///
    /// - Parameters:
    ///   - fileName: The file name on disk space.
    ///   - isGroupContainer: set `true` if the requested file should be lookup in a group container.
    /// - Returns: Return `true` if the requested file exist.
    func isExist(fileName: String) -> Bool

    /// Save file.
    ///
    /// - Parameters:
    ///   - data: `Codable` object that will be saved.
    ///   - toFileName: The file name on disk space.
    func save<T: Codable>(data: T, toFileName: String) throws

    /// Save file.
    ///
    /// - Parameters:
    ///   - data: Raw data
    ///   - toFileName: The file name on disk space.
    func saveData(data: Data, toFileName: String) throws

    /// Load file.
    ///
    /// - Parameters:
    ///   - fileName: The file name on disk space.
    /// - Returns: Return `Data` if file will be found, or `nil` if not.
    func loadData(fileName: String) throws -> Data

    /// Load file.
    ///
    /// - Parameters:
    ///   - fileName: The file name on disk space.
    /// - Returns: Return `Codable` if file will be found, or `nil` if not.
    func load<T: Codable>(fileName: String) throws -> T

    /// Delete file.
    ///
    /// - Parameters:
    ///   - fileName: The file name on disk space.
    func delete(fileName: String) throws
}

public final class FileStorageImpl {
    private enum Constants {
        static let folderName = "OptimoveSDK"
    }

    private let fileManager: FileManager
    private let directoryURL: URL

    public init(url: URL) throws {
        fileManager = FileManager.default
        directoryURL = url
    }

    private func addSkipBackupAttributeToItemAtURL(fileURL: URL) throws {
        var url = fileURL
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try url.setResourceValues(resourceValues)
    }

    private func getDirectory() -> URL {
        return directoryURL.appendingPathComponent(Constants.folderName)
    }
}

extension FileStorageImpl: FileStorage {
    public func isExist(fileName: String) -> Bool {
        let url = getDirectory()
        let fileUrl = url.appendingPathComponent(fileName)
        return fileManager.fileExists(atPath: fileUrl.path)
    }

    public func loadData(fileName: String) throws -> Data {
        let fileUrl = getDirectory().appendingPathComponent(fileName)
        do {
            let contents = try unwrap(fileManager.contents(atPath: fileUrl.path))
            Logger.debug("Load file at \(fileName)")
            return contents
        } catch {
            Logger.warn("Unable to load file \(fileName) at \(fileUrl.path). Reason: \(error.localizedDescription)")
            throw error
        }
    }

    public func load<T: Codable>(fileName: String) throws -> T {
        let data = try loadData(fileName: fileName)
        return try JSONDecoder().decode(T.self, from: data)
    }

    public func save<T: Encodable>(
        data: T,
        toFileName fileName: String
    ) throws {
        let data = try JSONEncoder().encode(data)
        try saveData(data: data, toFileName: fileName)
    }

    public func saveData(
        data: Data,
        toFileName fileName: String
    ) throws {
        do {
            let url = getDirectory()
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

    public func delete(fileName: String) throws {
        do {
            let fileUrl = getDirectory().appendingPathComponent(fileName)
            try fileManager.removeItem(at: fileUrl)
            Logger.debug("File deleted at \(fileUrl.absoluteString).")
        } catch {
            Logger.error("Unable to delete file \(fileName). Reason: \(error.localizedDescription)")
            throw error
        }
    }
}
