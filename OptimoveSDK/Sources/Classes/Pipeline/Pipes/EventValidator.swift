//  Copyright © 2017 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class EventValidator: Pipe {

    private let configuration: Configuration
    private let storage: OptimoveStorage

    init(configuration: Configuration,
         storage: OptimoveStorage) {
        self.configuration = configuration
        self.storage = storage
    }

    override func deliver(_ operation: CommonOperation) throws {
        let validationFunction = { [configuration] () throws -> CommonOperation in
            switch operation {
            case let .report(events: events):
                do {
                    let validatedEvents: [Event] = try events.filter { event in
                        let errors = try self.validate(event: event, withConfigs: configuration.events)
                        var include = true
                        errors.forEach { error in
                            Logger.buisnessLogicError(error.localizedDescription)
                            switch error {
                            case .alreadySetInUserEmail, .alreadySetInUserId:
                                include = false
                                break
                            }
                        }

                        return include
                    }
                    return CommonOperation.report(events: validatedEvents)
                } catch {
                    if error is ValidationError {
                        Logger.buisnessLogicError(error.localizedDescription)
                        return CommonOperation.none
                    }
                    throw error
                }
            default:
                return operation
            }
        }
        try next?.deliver(validationFunction())
    }

    func verifySetUserIdEvent(_ event: Event) -> [ValidationError] {
        var errors: [ValidationError] = []
        if event.name == SetUserIdEvent.Constants.name,
           let userID = event.context[SetUserIdEvent.Constants.Key.userId] as? String {

            let user = User(userID: userID)
            let userID = user.userID.trimmingCharacters(in: .whitespaces)
            let validationResult = UserValidator(storage: storage).validateNewUser(user)
            switch validationResult {
            case .valid:
                NewUserHandler(storage: storage).handle(user: user)
            case .alreadySetIn:
                errors.append(ValidationError.alreadySetInUserId(userId: userID))
            }
        }
        return errors
    }

    func verifySetEmailEvent(_ event: Event) -> [ValidationError] {
        var errors: [ValidationError] = []
        if event.name == SetUserEmailEvent.Constants.name, let email = event.context[SetUserEmailEvent.Constants.Key.email] as? String {
            let validationResult = EmailValidator(storage: storage).isValid(email)
            switch validationResult {
            case .valid:
                NewEmailHandler(storage: storage).handle(email: email)
            case .alreadySetIn:
                errors.append(ValidationError.alreadySetInUserEmail(email: email))
            }
        }
        return errors
    }

    func validate(event: Event, withConfigs configs: [String: EventsConfig]) throws -> [ValidationError] {
        return [
            verifySetUserIdEvent(event),
            verifySetEmailEvent(event)
        ].flatMap { $0 }
    }

}

enum ValidationError: LocalizedError, Equatable {
    /// The errors below don't have official status, they're related only to the current implementation.
    case alreadySetInUserId(userId: String)
    case alreadySetInUserEmail(email: String)

    var errorDescription: String? {
        switch self {
        case let .alreadySetInUserId(userID):
            return "Optimove: User id '\(userID)' was already set in."
        case let .alreadySetInUserEmail(email):
            return "Optimove: Email '\(email)' was already set in."
        }
    }

    var status: Int {
        switch self {
        case .alreadySetInUserId: return 1_072
        case .alreadySetInUserEmail: return 1_081
        }
    }

}

extension String {

    private struct Constants {
        static let spaceCharacter = " "
        static let underscoreCharacter = "_"
    }

    func normilizeKey(with replacement: String = Constants.underscoreCharacter) -> String {
        return self.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: Constants.spaceCharacter, with: replacement)
    }
}
