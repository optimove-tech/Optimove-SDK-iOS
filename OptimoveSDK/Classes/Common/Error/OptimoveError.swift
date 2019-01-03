import Foundation

public enum OptimoveError:Error,Equatable
{
//    case noError
    case error(String)
//    case noNetwork
    case statusCodeInvalid
//    case noPermissions
    case invalidEvent
//    case optipushServerNotAvailable
//    case optipushComponentUnavailable
//    case optiTrackComponentUnavailable
    case illegalParameterLength
    case mismatchParamterType
    case mandatoryParameterMissing
//    case cantStoreFileInLocalStorage
//    case canNotParseData
    case emptyData

    case badRequest
    case notFound
    case gone
}
