//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import UserNotifications
import os.log
import OptimoveCore

final class MediaAttachmentDownloader: AsyncOperation {

    private let notificationPayload: NotificationPayload
    private let bestAttemptContent: UNMutableNotificationContent
    
    init(notificationPayload: NotificationPayload,
         bestAttemptContent: UNMutableNotificationContent) {
        self.notificationPayload = notificationPayload
        self.bestAttemptContent = bestAttemptContent
    }
    
    override func main() {
        state = .executing
        guard let media: MediaAttachment = notificationPayload.media else {
            os_log("Not found any media.", log: OSLog.downloader, type: .debug)
            state = .finished
            return
        }
        do {
            let fileIdentifier: String = try cast(media.url.lastPathComponent)
            os_log("Start downloading a media.", log: OSLog.downloader, type: .debug)
            let task = URLSession.shared.dataTask(with: media.url) { (data, response, error) in
                self.taskHandler(data: data, response: response, error: error, fileIdentifier: fileIdentifier)
            }
            task.resume()
        } catch {
            os_log("Error: %{PUBLIC}@", log: OSLog.downloader, type: .error, error.localizedDescription)
            state = .finished
        }
    }

}

extension MediaAttachmentDownloader {
    
    func taskHandler(data: Data?, response: URLResponse?, error: Error?, fileIdentifier: String) {
        if let error = error {
            os_log("Error: %{PUBLIC}@", log: OSLog.downloader, type: .error, error.localizedDescription)
            state = .finished
            return
        }
        do {
            let data: Data = try cast(data)
            try saveData(data, fileIdentifier: fileIdentifier)
        } catch {
            os_log("Error: %{PUBLIC}@", log: OSLog.downloader, type: .error, error.localizedDescription)
        }
        state = .finished
    }
    
    func saveData(_ data: Data, fileIdentifier: String) throws {
        let fileManager = FileManager.default
        let folderName = ProcessInfo.processInfo.globallyUniqueString
        let folderURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(folderName, isDirectory: true)
        try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        let fileURL = folderURL.appendingPathComponent(fileIdentifier)
        try data.write(to: fileURL)
        let attachment = try UNNotificationAttachment(identifier: fileIdentifier, url: fileURL)
        bestAttemptContent.attachments = [attachment]
        os_log("Media attachment added successfully", log: OSLog.downloader, type: .debug)
    }
    
}

extension OSLog {
    static let downloader = OSLog(subsystem: subsystem, category: "media_downloader")
}
