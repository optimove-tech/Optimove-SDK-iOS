//  Copyright © 2020 Optimove. All rights reserved.

import XCTest
import OptimoveCore
@testable import OptimoveSDK

class EventValidatorTests: OptimoveTestCase {

    var validator: EventValidator!
    var configuration: Configuration!

    override func setUpWithError() throws {
        let builder = ConfigurationBuilder(
            globalConfig: GlobalConfigFixture().build(),
            tenantConfig: TenantConfigFixture().build()
        )
        configuration = builder.build()
        validator = EventValidator(configuration: configuration, storage: storage)
    }

    func test_support_nondefined_parameters() throws {
        let event = StubEvent(context: [
            "nondefined_key": "nondefined_value"
        ])
        XCTAssertNoThrow( try validator.deliver(.report(events: [event])))
    }

    func test_cutting_mandatory_params() throws {
        let context: [String: Any] = [
            "1": "value",
            "2": "value",
            "3": "value",
            "4": "value",
            "5": "value",
            "6": "value",
            "7": "value",
            "8": "value",
            "9": "value",
            "10": "value",
            "11": "value"
        ]
        let parameters = context.keys.reduce(into: [:], { (acc, next) in
            acc[next] = Parameter(type: "String", optional: false)
        })
        let eventConfiguration = EventsConfig(
            id: 1,
            supportedOnOptitrack: true,
            supportedOnRealTime: true,
            parameters: parameters
        )
        let event = StubEvent(context: context)
        let errors = try validator.validate(event: event, withConfigs: [StubEvent.Constnats.name: eventConfiguration])
        XCTAssertEqual(errors.count, 2)
    }

    func test_cutting_non_mandatory_params() throws {
        let context: [String: Any] = [
            "1": "value",
            "2": "value",
            "3": "value",
            "4": "value",
            "5": "value",
            "6": "value",
            "7": "value",
            "8": "value",
            "9": "value",
            "10": "value",
            "11": "value"
        ]
        let parameters = context.keys.reduce(into: [:], { (acc, next) in
            acc[next] = Parameter(type: "String", optional: true)
        })
        let eventConfiguration = EventsConfig(
            id: 1,
            supportedOnOptitrack: true,
            supportedOnRealTime: true,
            parameters: parameters
        )
        let event = StubEvent(context: context)
        let errors = try validator.validate(event: event, withConfigs: [StubEvent.Constnats.name: eventConfiguration])
        XCTAssertEqual(errors.count, 1)
    }

    // MARK: - verifyAllowedNumberOfParameters

    func test_verifyAllowedNumberOfParameters_no_error() {
        let context: [String: Any] = [
            "1": "value",
            "2": "value",
            "3": "value",
            "4": "value",
            "5": "value",
            "6": "value",
            "7": "value",
            "8": "value",
            "9": "value",
            "10": "value"
        ]
        let event = StubEvent(context: context)
        let errors = validator.verifyAllowedNumberOfParameters(event)
        XCTAssertEqual(errors.count, 0)
    }

    func test_verifyAllowedNumberOfParameters_limitOfParameters_error() {
        let context: [String: Any] = [
            "1": "value",
            "2": "value",
            "3": "value",
            "4": "value",
            "5": "value",
            "6": "value",
            "7": "value",
            "8": "value",
            "9": "value",
            "10": "value",
            "11": "value"
        ]
        let event = StubEvent(context: context)
        let errors = validator.verifyAllowedNumberOfParameters(event)
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(
            errors[0],
            ValidationError.limitOfParameters(
                name: StubEvent.Constnats.name,
                actual: context.count,
                limit: configuration.optitrack.maxActionCustomDimensions
            )
        )
    }

    // MARK: - verifyMandatoryParameters

    func test_verifyMandatoryParameters_no_errors() {
        let mandatoryKey = "1"
        let event = StubEvent(context: [
            mandatoryKey: "value"
        ])
        let eventConfiguration = EventsConfig(
            id: 1,
            supportedOnOptitrack: true,
            supportedOnRealTime: true,
            parameters: [
                mandatoryKey: Parameter(type: "String", optional: false)
            ]
        )
        let errors = validator.verifyMandatoryParameters(eventConfiguration, event)
        XCTAssertEqual(errors.count, 0)
    }

    func test_verifyMandatoryParameters_undefinedMandatoryParameter_error() {
        let mandatoryKey = "1"
        let mandatoryKey2 = "2"
        let mandatoryKey3 = "3"
        let event = StubEvent(context: [:])
        let eventConfiguration = EventsConfig(
            id: 1,
            supportedOnOptitrack: true,
            supportedOnRealTime: true,
            parameters: [
                mandatoryKey: Parameter(type: "String", optional: false),
                mandatoryKey2: Parameter(type: "Number", optional: false),
                mandatoryKey3: Parameter(type: "Boolean", optional: false)
            ]
        )
        let errors = validator.verifyMandatoryParameters(eventConfiguration, event)
        XCTAssertEqual(errors.count, 3)
    }

    // MARK: - verifySetUserIdEvent

    func test_verifySetUserIdEvent_tooLongUserId_error() throws {
        let userId = String(repeating: "A", count: EventValidator.Constants.legalUserIdLength + 1)
        let event = SetUserIdEvent(
            originalVistorId: "original",
            userId: userId,
            updateVisitorId: ""
        )
        let errors = validator.verifySetUserIdEvent(event)
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(
            errors[0],
            ValidationError.tooLongUserId(userId: userId, limit: EventValidator.Constants.legalUserIdLength)
        )
        XCTAssertNil(storage.customerID)
    }

    func test_verifySetUserIdEvent_invalidUserId_error() throws {
        let userId = ""
        let event = SetUserIdEvent(
            originalVistorId: "original",
            userId: userId,
            updateVisitorId: ""
        )
        let errors = validator.verifySetUserIdEvent(event)
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(
            errors[0],
            ValidationError.invalidUserId(userId: userId)
        )
        XCTAssertNil(storage.customerID)
    }

    func test_verifySetUserIdEvent_no_errors() throws {
        let userId = "abc"
        let event = SetUserIdEvent(
            originalVistorId: "original",
            userId: userId,
            updateVisitorId: ""
        )
        let errors = validator.verifySetUserIdEvent(event)
        XCTAssertEqual(errors.count, 0)
        XCTAssertEqual(storage.customerID, userId)
    }

    func test_verifySetUserIdEvent_alreadySetInUserId_error() throws {
        let userId = "abc"
        storage.customerID = userId
        let event = SetUserIdEvent(
            originalVistorId: "original",
            userId: userId,
            updateVisitorId: ""
        )
        
        let errors = validator.verifySetUserIdEvent(event)
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(
            errors[0],
            ValidationError.alreadySetInUserId(userId: userId)
        )
    }

    // MARK: - verifySetEmailEvent

    func test_verifySetEmailEvent_no_errors() throws {
        let email = "abcABC%-90@abcABC-.abcABC"
        let event = SetUserEmailEvent(email: email)
        let errors = validator.verifySetEmailEvent(event)
        XCTAssertEqual(errors.count, 0)
        XCTAssertEqual(storage.userEmail, email)
    }

    func test_verifySetEmailEvent_emailAlreadySet_error() throws {
        let email = "abcABC%-90@abcABC-.abcABC"
        storage.userEmail = email
        let event = SetUserEmailEvent(email: email)
        let errors = validator.verifySetEmailEvent(event)
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(
            errors[0],
            ValidationError.alreadySetInUserEmail(email: email)
        )
    }

    func test_verifySetEmailEvent_invalidEmail_error() throws {
        let email = "abcABC%-90abcABC-.abcABC"
        let event = SetUserEmailEvent(email: email)
        let errors = validator.verifySetEmailEvent(event)
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(
            errors[0],
            ValidationError.invalidEmail(email: email)
        )
        XCTAssertNil(storage.userEmail)
    }

    // MARK: - verifyEventParameters

    func test_verifyEventParameters_undefinedParameter_error() throws {
        let key = "wrongKey"
        let event = StubEvent(context: [
            key: "value"
        ])
        let eventConfiguration = EventsConfig(
            id: 1,
            supportedOnOptitrack: true,
            supportedOnRealTime: true,
            parameters: [
                "rightKey": Parameter(type: "String", optional: false)
            ]
        )
        let errors = try validator.verifyEventParameters(event, eventConfiguration)
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(
            errors[0],
            ValidationError.undefinedParameter(key: key)
        )
    }

    func test_validate_undefinedName_error() throws {
        let key = "wrongKey"
        let event = StubEvent(context: [
            key: "value"
        ])
        let eventConfiguration = EventsConfig(
            id: 1,
            supportedOnOptitrack: true,
            supportedOnRealTime: true,
            parameters: [
                "rightKey": Parameter(type: "String", optional: false)
            ]
        )
        let configs = [
            "name": eventConfiguration
        ]
        let errors = try validator.validate(event: event, withConfigs: configs)
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(
            errors[0],
            ValidationError.undefinedName(name: StubEvent.Constnats.name)
        )
    }

    func test_validateParameter_wrongType_number_error() throws {
        let key = "key"
        let value = "string"
        let parameter = Parameter(type: "Number", optional: false)
        do {
            try validator.validateParameter(parameter, key, value)
        } catch {
            XCTAssertEqual(error as! ValidationError, ValidationError.wrongType(key: key, expected: .number))
        }
    }
    func test_validateParameter_limitOfCharacters_number_error() throws {
        let key = "key"
        let value = Int64.max
        let parameter = Parameter(type: "Number", optional: false)
        do {
            try validator.validateParameter(parameter, key, value)
        } catch {
            XCTAssertEqual(
                error as! ValidationError,
                ValidationError.limitOfCharacters(
                    key: key,
                    limit: EventValidator.Constants.legalParameterLength
                )
            )
        }
    }

    func test_validateParameter_wrongType_string_error() throws {
        let key = "key"
        let value = 1
        let parameter = Parameter(type: "String", optional: false)
        do {
            try validator.validateParameter(parameter, key, value)
        } catch {
            XCTAssertEqual(error as! ValidationError, ValidationError.wrongType(key: key, expected: .string))
        }
    }

    func test_validateParameter_limitOfCharacters_string_error() throws {
        let key = "key"
        let value = String(repeating: "A", count: EventValidator.Constants.legalParameterLength + 1)
        let parameter = Parameter(type: "String", optional: false)
        XCTAssertThrowsError(try validator.validateParameter(parameter, key, value)) { (error) in
            XCTAssertEqual(
                error as! ValidationError,
                ValidationError.limitOfCharacters(
                    key: key,
                    limit: EventValidator.Constants.legalParameterLength
                )
            )
        }
    }

    func test_validateParameter_wrongType_boolean_error() throws {
        let key = "key"
        let value = "string"
        let parameter = Parameter(type: "Boolean", optional: false)
        do {
            try validator.validateParameter(parameter, key, value)
        } catch {
            XCTAssertEqual(error as! ValidationError, ValidationError.wrongType(key: key, expected: .boolean))
        }
    }

}
