//
//  Optimove + reportScreenVisit.swift
//  OptimoveSDK

import Foundation

// MARK: report screen visit

extension Optimove
{
    @objc public func setScreenVisit(screenPathArray: [String], screenTitle: String, screenCategory: String? = nil)
    {
        OptiLoggerMessages.logReportScreen()
        guard !screenTitle.trimmingCharacters(in: .whitespaces).isEmpty else {
            OptiLoggerMessages.logReportScreenWithEmptyTitleError()
            return
        }
        let path = screenPathArray.joined(separator: "/")
        setScreenVisit(screenPath: path, screenTitle: screenTitle, screenCategory: screenCategory)
    }

    @objc public func setScreenVisit(screenPath: String, screenTitle: String, screenCategory: String? = nil)
    {
        let screenTitle = screenTitle.trimmingCharacters(in: .whitespaces)
        var screenPath = screenPath.trimmingCharacters(in: .whitespaces)
        guard !screenTitle.isEmpty else {
            OptiLoggerMessages.logReportScreenWithEmptyTitleError()
            return
        }
        guard !screenPath.isEmpty else {
            OptiLoggerMessages.logReportScreenWithEmptyScreenPath()
            return
        }

        if screenPath.starts(with: "/") {
            screenPath = String(screenPath[screenPath.index(after: screenPath.startIndex)...])
        }
        if let customUrl = removeUrlProtocol(path: screenPath).lowercased().addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
            var path = customUrl.last != "/" ? "\(customUrl)/" : "\(customUrl)"
            path = "\(Bundle.main.bundleIdentifier!)/\(path)".lowercased()

            if RunningFlagsIndication.isComponentRunning(.optiTrack) {
                optiTrack.reportScreenEvent(screenTitle: screenTitle, screenPath: path, category: screenCategory)
            }
            if RunningFlagsIndication.isComponentRunning(.realtime) {
                realTime.reportScreenEvent(customURL: path, pageTitle: screenTitle, category: screenCategory)
            }
        }
    }

    private func removeUrlProtocol(path: String) -> String {
        var result = path
        for prefix in ["https://www.", "http://www.", "https://", "http://"] {
            if (result.hasPrefix(prefix)) {
                result.removeFirst(prefix.count)
                break
            }
        }
        return result
    }
}
