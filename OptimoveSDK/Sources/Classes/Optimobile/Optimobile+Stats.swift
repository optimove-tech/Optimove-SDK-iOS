//  Copyright © 2022 Optimove. All rights reserved.

import Foundation
import OptimoveCore
import UserNotifications

#if os(iOS) || os(watchOS) || os(tvOS)
    import UIKit
#endif

enum OSTypeID: NSNumber {
    case osTypeIDiOS = 1
    case osTypeIDOSX
    case osTypeIDAndroid
    case osTypeIDWindowsPhone
    case osTypeIDWindow
}

enum RuntimeType: NSNumber {
    case runtimeTypeUnknown = 0
    case runtimeTypeNative
    case runtimeTypeXamarin
    case runtimeTypeCordova
    case runtimeTypeJavaRuntime
}

enum TargetType: Int {
    case targetTypeDebug = 1
    case targetTypeRelease
}

enum Platform {
    static let isSimulator: Bool = {
        var isSim = false
        // if mac architechture and os is iOS, WatchOS or TVOS we're on a simulator
        #if targetEnvironment(simulator)
            isSim = true
        #endif
        return isSim
    }()

    static let isMacintosh: Bool = {
        var isMac = false
        // check architechture for mac
        #if arch(i386) || arch(x86_64)
            isMac = true
        #endif
        return !isSimulator && isMac
    }()
}

extension Optimobile {
    func sendDeviceInformation(config: OptimobileConfig) {
        let target = getTarget(config: config)

        var app = [String: AnyObject]()
        app["bundle"] = Bundle.main.infoDictionary!["CFBundleIdentifier"] as AnyObject?
        app["version"] = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as AnyObject?
        app["target"] = target.rawValue as AnyObject?

        let sdk = getSdkInfo(config: config)
        let runtime = getRuntimeInfo(config: config)

        var os = [String: AnyObject]()
        var device = [String: AnyObject]()

        let timeZone = TimeZone.autoupdatingCurrent
        let tzName = timeZone.identifier
        device["tz"] = tzName as AnyObject?
        device["name"] = Sysctl.model as AnyObject?

        if Platform.isMacintosh {
            os["id"] = OSTypeID.osTypeIDOSX.rawValue
            os["version"] = ProcessInfo.processInfo.operatingSystemVersionString as AnyObject?
        } else {
            os["id"] = OSTypeID.osTypeIDiOS.rawValue
            os["version"] = UIDevice.current.systemVersion as AnyObject?
        }

        if NSLocale.preferredLanguages.count >= 1 {
            device["locale"] = NSLocale.preferredLanguages[0] as AnyObject
        }

        device["isSimulator"] = Platform.isSimulator as AnyObject?

        let finalParameters = [
            "app": app,
            "sdk": sdk,
            "runtime": runtime,
            "os": os,
            "device": device,
            "ios": getiOSAttrs(),
        ]

        Optimobile.trackEvent(eventType: OptimobileEvent.STATS_CALL_HOME.rawValue, properties: finalParameters)
    }

    private func getSdkInfo(config: OptimobileConfig) -> [String: AnyObject] {
        if let overridden = config.sdkInfo {
            return overridden
        }

        return [
            "id": sdkType as AnyObject,
            "version": SDKVersion as AnyObject,
        ]
    }

    private func getRuntimeInfo(config: OptimobileConfig) -> [String: AnyObject] {
        if let overridden = config.runtimeInfo {
            return overridden
        }

        var runtime = [
            "id": RuntimeType.runtimeTypeNative.rawValue as AnyObject,
        ]

        if Platform.isMacintosh {
            runtime["version"] = ProcessInfo.processInfo.operatingSystemVersionString as AnyObject?
        } else {
            runtime["version"] = UIDevice.current.systemVersion as AnyObject?
        }

        return runtime
    }

    private func getTarget(config: OptimobileConfig) -> TargetType {
        if let overridden = config.isRelease {
            return overridden == true ? TargetType.targetTypeRelease : TargetType.targetTypeDebug
        }

        var target = TargetType.targetTypeRelease

        // http://stackoverflow.com/questions/24111854/in-absence-of-preprocessor-macros-is-there-a-way-to-define-practical-scheme-spe
        #if DEBUG
            target = TargetType.targetTypeDebug
        #endif

        return target
    }

    private func getiOSAttrs() -> [String: Any] {
        var push = [
            "scheduled": false,
            "timeSensitive": false,
        ]

        if #available(iOS 15.0, *) {
            let permsBarrier = DispatchSemaphore(value: 0)

            UNUserNotificationCenter.current().getNotificationSettings { settings in
                push["scheduled"] = settings.scheduledDeliverySetting == .enabled
                push["timeSensitive"] = settings.timeSensitiveSetting == .enabled

                permsBarrier.signal()
            }

            _ = permsBarrier.wait(timeout: DispatchTime.now() + DispatchTimeInterval.seconds(5))
        }

        return [
            "hasGroup": AppGroupsHelper.isAppGroupDefined(),
            "push": push,
        ]
    }
}
