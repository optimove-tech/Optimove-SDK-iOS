//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

final class OptiLoggerMessages {

    static func logError(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil,
        error: Error
        ) {

        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            error.localizedDescription
        )
    }

    // MARK: SDK Initialization

    static func logPathToRemoteConfiguration(
        path: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {

        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Connect to \(path) to retreive configuration file "
        )
    }

    static func logInitializtionOfInsitalizerStart(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Initialize OptimoveComponentInitializer"
        )
    }

    static func logInitializerInitializtionFinish(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "Optimove"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Finish OptimoveComponentInitializer initialization"
        )
    }

    static func logStartOfLocalInitializtion(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "Optimove"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .info,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "start initializtion from local configurations"
        )
    }

    static func logSetupComponentsFromRemote(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "Optimove"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "setup components from remote"
        )
    }

    static func logConfigFileNotExist(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "Optimove"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "configurtion file not exist"
        )
    }

    static func logConfigurationFileArrivedFromRemote(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "Optimove"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .info,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "file arrived 😃 "
        )
    }

    static func logLocalFetchFailure(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "Optimove"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "error when fetching configurstion file from local storage"
        )
    }

    static func logLocalConfigFileFetchSuccess(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "Optimove"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Got configuration file from local storage "
        )
    }

    static func logIssueWithConfigFile(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "Optimove"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "configuration data corrupt"
        )
    }

    static func logSetupCopmponentsFromLocalConfiguraitonStart(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "Optimoe"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "setup components from local"
        )
    }

    static func logConfigurationParsingError(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "Optimove"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "local configuration could not be parsed"
        )
    }

    static func logSuccessfulyFinishOfComponentsSetup(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "Optimove"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .info,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "All components setup finished"
        )
    }

    static func logSdkAlreadyRunning(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "Optimove"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "SDK already running, skip initialization before lock"
        )
    }

    static func logEventsWarehouseInitializtionStart(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "Optimove"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Initialize events warehouse"
        )
    }

    static func logEventsWarehouseInitializtionFinish(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "Optimove"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Finished initialization of events warehouse"
        )
    }

    // MARK: Event Validation
    static func logParameterIsNotNumber(
        name: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "Optimove"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "parameter \(name) is not number type"
        )
    }

    static func logParameterIsNotString(
        name: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "Optimove"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "parameter \(name) is not string type"
        )
    }

    static func logParameterIsNotBoolean(
        name: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "Optimove"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "parameter \(name) is not boolean type"
        )
    }

    // MARK: Device Permissions
    static func logIdfaPermissionMissing(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "Optimove"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .warn,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "enable IDFA key missing"
        )
    }

    // MARK: Network Requests
    static func logRequesterror(
        errorDescription: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "Optimove"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "request error:\(errorDescription)"
        )
    }

    static func logResponseError(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Issue with response"
        )
    }

    static func logStoringFileStatus(
        name: String,
        successStatus: String,
        fileLocation: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "Optimove"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Storing status of \(name) is \(successStatus)\n location:\(fileLocation)"
        )
    }

    static func logStringFailureStatus(
        name: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: name,
            methodName: methodName,
            logModule: logModule,
            "❌ Storing process of \(name) failed\n"
        )
    }

    static func logLoadFile(
        fileUrl: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "load content from \(fileUrl)"
        )
    }

    static func logLoadFileFailure(
        name: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: name,
            methodName: methodName,
            logModule: logModule,
            "contents could not be loaded from \(name)"
        )
    }

    static func logDeleteFile(
        name: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: name,
            methodName: methodName,
            logModule: logModule,
            "Delete file \(name)"
        )
    }

    static func logFileDeletionFailure(
        name: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: name,
            methodName: methodName,
            logModule: logModule,
            "Could not delete file \(name)"
        )
    }

    static func logConfigForEventMissing(
        eventName: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "configurations for event: \(eventName) are missing"
        )
    }

    // MARK: Realtime

    static func logOfflineStatusForRealtime(
        eventName: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .warn,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Device is offline, skip realtime event reporting \(eventName)"
        )
    }

    static func logRealtimeReportEvent(
        json: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "RealTime"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "report event to realtime with JSON: \(json)"
        )
    }

    static func logRealtimeRequestFailure(
        errorDescription: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "RealTime"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "request to realtime failed: \(errorDescription)"
        )
    }

    static func logRealtimeReportStatus(
        json: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "RealTime"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "real time report status:\(json)"
        )
    }

    static func logRealtimeSetUserIdEncodeFailure(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "RealTime"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "could not encode realtime set user id request"
        )
    }

    static func logSkipSetUserIdForRealtime(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "RealTime"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .warn,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Device is offline, skip realtime event set user id"
        )
    }

    static func logSkipSetEmailForRealtime(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "RealTime"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .warn,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Device is offline, skip realtime event set email"
        )
    }

    static func logRealtimeSetUserIdStatus(
        status: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "RealTime"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "real time set user id status:\(status)"
        )
    }

    static func logRealtimeSetEmailStatus(
        status: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "RealTime"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "real time set email status:\(status)"
        )
    }

    static func logRealtimeSetEmailEncodeFailure(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "RealTime"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "could not encode realtime set email request"
        )
    }

    static func logConfigrureRealtime(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "RealTime"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Configure Realtime"
        )
    }

    static func logRealtimeConfiguirationFailure(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "👎🏻 real time configurations invalid"
        )
    }

    static func logRealtimeCOnfigurationSuccess(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .info,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "👍🏻 Realtime configuration succeed"
        )
    }

    // MARK: OptiTrack

    static func logConfugurationForEventMissing(
        eventName: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "configurations for event: \(eventName) are missing"
        )
    }

    static func logOptitrackSetUserID(
        userId: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .info,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Optitrack set User id for \(userId)"
        )
    }

    static func logOptitrackDispatchRequest(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "user asked to dispatch"
        )
    }

    static func logOptitrackNotRunning(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .warn,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "optitrack component not running"
        )
    }

    static func logOptitrackReport(
        event: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "report \(event) to optitrack"
        )
    }

    static func logLoadingConfigsError(
        ofEvent event: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "could not load \(event) event configs"
        )
    }

    static func logConfigureOptitrack(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Configure OptiTrack"
        )
    }

    static func logOptitrackConfigurationInvalid(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .warn,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "👎🏻 OptiTrack configuration invalid"
        )
    }

    static func logOptitrackConfigurationSuccess(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .info,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "👍🏻 OptiTrack configuration succeed"
        )
    }

    static func logAddEventsFromQueue(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Add events from queue"
        )
    }

    static func logEventsfileCouldNotLoad(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Events file could not be saved."
        )
    }

    static func logReportScreenEvent(
        screenTitle: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "report screen event of \(screenTitle)"
        )
    }

    static func logRemoveEventsFromQueue(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Remove events from queue"
        )
    }

    static func logEventFileSaveFailure(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Events file could not be saved."
        )
    }

    // MARK: OptiPush

    static func logClientreceiveFcmTOkenForTheFirstTime(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Client receive a token for the first time"
        )
    }

    static func logUserOptOPutFirstTime(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "User Opt for first time"
        )
    }

    static func logUserNotificationAuthorizedByUser(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .info,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Notification authorized by user"
        )
    }

    static func logOptinRequest(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "SDK make opt in request"
        )
    }

    static func logUserNotificationRejectedByUser(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Notification unauthorized by user"
        )
    }

    static func logOptoutRequest(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "SDK make opt OUT request"
        )
    }

    static func logOptOutFirstLaunch(fileName: String = #file, methodName: String = #function, logModule: String? = nil) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "User Opt out at first launch"
        )
    }

    static func logConfigureOptipush(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Configure Optipush"
        )
    }

    static func logOptipushConfigurationFailure(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "👎🏻 Optipush configurations invalid"
        )
    }

    static func logOptipushConfigurationSuccess(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .info,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "👍🏻 OptiPush configuration succeed"
        )
    }

    static func logUserUseAutonomousFirebase(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .info,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Indication of hosted firebase"
        )
    }

    static func logUserNotUseOwnFirebase(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .info,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Indication of not hosted firebase"
        )
    }

    static func logSetupFirebase(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Setup firebase"
        )
    }

    static func logFirebaseStupFinished(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "firebase finish setup"
        )
    }

    static func logFcmTOkenRetreiveError(
        errorDescription: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "could not retreive dedicated fcm token with error \(errorDescription)"
        )
    }

    static func logFcmTokenNotNew(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "fcm token is not new, no need to refresh"
        )
    }

    static func logAppControllerNotConfigure(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "app controller not configure"
        )
    }

    static func logOldFcmToken(
        token: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "🚀 FCM token old: \(token)"
        )
    }

    static func logNewFcmToken(
        token: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "🚀 FCM token new: \(token)"
        )
    }

    static func logFcmTokenForAppController(
        fcmToken: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "🚀 FCM token for app controller: \(fcmToken)"
        )
    }

    static func logRegistrarInitializtionStart(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Start Initialize Registrar"
        )
    }

    static func logRegistrarInitializtionFinish(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Finish Initialize Registrar"
        )
    }

    static func logMbaasRequestUrlEncodeError(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "could not locate url for mbaas operation"
        )
    }

    static func logRetryFailed(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "retry request failed, lets try next time..."
        )
    }

    static func logJsonBuildFailure(
        mbaasRequestOperation: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "could not build Json object of \(mbaasRequestOperation)"
        )
    }

    static func logSendMbaasRequest(
        url: URL,
        json: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "send request to \(url) with body: \(json)"
        )
    }

    static func logMbaasRequestError(
        mbaasRequestOperation: String,
        errorDescription: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "\(mbaasRequestOperation) error: \(errorDescription)"
        )
    }

    static func logMbaasResponse(
        mbaasRequestOperation: String,
        response: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "\(mbaasRequestOperation) response: \(response)"
        )
    }

    // MARK: Gateway

    static func logReportScreen(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "user ask to report screen event"
        )
    }

    static func logReportScreenWithEmptyTitleError(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "trying to report screen visit with empty title"
        )
    }

    static func logReportScreenWithEmptyScreenPath(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Tried to pass empty screenPath to report Screen Visit"
        )
    }

    static func logStartConfigureOptimoveSDK(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .info,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Start Configure Optimove SDK"
        )
    }

    static func logNormalInitFailed(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .warn,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Normal initialization failed"
        )
    }

    static func logNormalInitSuccess(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .info,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Normal Initialization success"
        )
    }

    static func logStoreUserInfo(
        tenantToken: String,
        tenantVersion: String,
        tenantUrl: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "stored user info in local storage: \n" + "token:\(tenantToken)\n" + "version:\(tenantVersion)\n"
                + "end point:\(tenantUrl)\n"
        )
    }

    static func logStartInitFromRemote(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Start Optimove component initialization from remote"
        )
    }

    static func logSkipNormalInitSinceRunning(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .info,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Skip normal initializtion since SDK already running"
        )
    }

    static func logStartUrgentInitProcess(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .info,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Start Optimove urgent initiazlition process"
        )
    }

    static func logSkipUrgentInitSinceRunning(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Skip urgent initializtion since SDK already running"
        )
    }

    static func logReceiveRemoteNotification(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Receive Remote Notification"
        )
    }

    static func logReceiveNotificationInForeground(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "received notification in foreground mode"
        )
    }

    static func logNotificationShouldNotHandleByOptimove(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "notification should not be handled by optimove"
        )
    }

    static func logNotificationResponse(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "user respond to non optimove notification"
        )
    }

    static func logConfigurationForEventMissing(
        eventName: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "configurations for event: \(eventName) are missing"
        )
    }

    static func logReportEventFailed(
        eventName: String,
        eventValidationError: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "report event \(eventName) is invalid with error \(eventValidationError)"
        )
    }

    static func logOptiTrackNotRunning(
        eventName: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "\(eventName) could not be reported to optitrack since it is not running"
        )
    }

    static func logRealtimeReportEvent(
        eventName: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "report \(eventName) to realtime"
        )
    }

    static func logEventNotsupportedOnRealtime(
        eventName: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "\(eventName) is not supported on realtime"
        )
    }

    static func logRealtimeNotrunning(
        eventName: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "\(eventName) could not be reported to realtime since it is not running"
        )
    }

    static func logUserIdNotValid(
        userID: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "user id \(userID) is not valid"
        )
    }

    static func logUserIdNotNew(
        userId: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "Optimove"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .warn,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "User Id \(userId) was already set in the Optimove SDK"
        )
    }

    static func logOptitrackNotRunningForSetUserId(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "set user id failed since optitrack not running"
        )
    }

    static func logOptipushNOtRunningForRegistration(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "register use failed since optipush not running"
        )
    }

    static func logEmailNotValid(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = "Optimove"
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "email is not valid"
        )
    }

    static func logRequestToRegister(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "request to reregister"
        )
    }

    static func logRequestToPing(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "request to ping"
        )
    }

    static func logRemainBackgroundTime(
        backgroundTimeRemaining: TimeInterval,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "background time remaining is \(backgroundTimeRemaining)"
        )
    }

    static func logUserReactToNotification(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "User react to notification"
        )
    }

    static func logUserReaction(
        userResponseToNotification: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .info,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Action = \(userResponseToNotification)"
        )
    }

    static func logCampignDetailsCouldNotBeExtracted(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .warn,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "campaign details could not be extracted - Probably received a test campaign"
        )
    }

    static func logDeepLinkNotExtractedWithReason(
        errorDescription: String,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Deep link could not be extracted. error: \(errorDescription)"
        )
    }

    static func logStoreDeepLink(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "store dynamic link of message"
        )
    }

    static func logUrgentInitFailed(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Urgent initializtion failed"
        )
    }

    static func logUrgentInitSuccess(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Urgent Initialization success"
        )
    }

    static func logAnalyzenotification(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "Analyze notification"
        )
    }

    static func logCommandNotificationFailure(
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .error,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "could not parse sdk command"
        )
    }

    static func logDeviceRequirementNil(
        requiredService: OptimoveDeviceRequirement,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "deviceRequirementStatuses[\(requiredService.description)] returns nil"
        )
    }

    static func logRegisterToReceiveRequirementStatus(
        requiredService: OptimoveDeviceRequirement,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "register closure to receive \(requiredService.description) status"
        )
    }

    static func logGetStatusOf(
        requiredService: OptimoveDeviceRequirement,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "get status from fetcher of \(requiredService.description)"
        )
    }

    static func logRequirementtatus(
        deviceRequirement: OptimoveDeviceRequirement,
        status: Bool,
        fileName: String = #file,
        methodName: String = #function,
        logModule: String? = nil
    ) {
        OptiLoggerStreamsContainer.log(
            level: .debug,
            fileName: fileName,
            methodName: methodName,
            logModule: logModule,
            "\(deviceRequirement.description) status is : \(status)"
        )
    }

}
