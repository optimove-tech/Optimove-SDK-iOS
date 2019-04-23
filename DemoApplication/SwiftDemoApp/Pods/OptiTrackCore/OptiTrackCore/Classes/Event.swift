//
//  Event.swift
//  PiwikTracker
//
//  Created by Cornelius Horstmann on 21.12.16.
//  Copyright © 2016 PIWIK. All rights reserved.
//

import Foundation
import CoreGraphics

/// Represents an event of any kind.
///
/// - Note: Should we store the resolution in the Event (cleaner) or add it before transmission (smaller)?
/// - Todo:
///     - Add Campaign Parameters: _rcn, _rck
///     - Add Action info
///     - Event Tracking info
///     - Add Content Tracking info
///     - Add Ecommerce info
///
/// # Key Mapping:
/// Most properties represent a key defined at: [Tracking HTTP API](https://developer.piwik.org/api-reference/tracking-api). Keys that are not supported for now are:
///
/// - idsite, rec, rand, apiv, res, cookie,
/// - All Plugins: fla, java, dir, qt, realp, pdf, wma, gears, ag
/// - cid: We will use the uid instead of the cid.
public struct Event: Codable {
    let siteId: String
    public let uuid: NSUUID
    let visitor: Visitor
    let session: Session

    /// The Date and Time the event occurred.
    /// api-key: h, m, s
    let date: Date

    /// The full URL for the current action.
    /// api-key: url
    let url: URL?

    /// api-key: action_name
    let actionName: [String]

    /// The language of the device.
    /// Should be in the format of the Accept-Language HTTP header field.
    /// api-key: lang
    let language: String

    /// Should be set to true for the first event of a session.
    /// api-key: new_visit
    let isNewSession: Bool

    /// Currently only used for Campaigns
    /// api-key: urlref
    let referer: URL?
    var screenResolution : CGSize = Device.makeCurrentDevice().screenSize

    /// api-key: _cvar
    let customVariables: [CustomVariable]

    /// Event tracking
    /// https://piwik.org/docs/event-tracking/
    let eventCategory: String?
    let eventAction: String?
    let eventName: String?
    let eventValue: Float?

    /// Campaign tracking
    /// https://matomo.org/docs/tracking-campaigns/
    let campaignName: String?
    let campaignKeyword: String?

    /// Search tracking
    /// api-keys: search, search_cat, search_count
    let searchQuery: String?
    let searchCategory: String?
    let searchResultsCount: Int?

    let dimensions: [CustomDimension]

    let customTrackingParameters: [String:String]

    /// Content tracking
    /// https://matomo.org/docs/content-tracking/
    let contentName: String?
    let contentPiece: String?
    let contentTarget: String?
    let contentInteraction: String?

    /// Goal tracking
    /// https://matomo.org/docs/tracking-goals-web-analytics/
    let goalId: Int?
    let revenue: Float?

    /// Ecommerce Order tracking
    /// https://matomo.org/docs/ecommerce-analytics/#tracking-ecommerce-orders-items-purchased-required
    let orderId: String?
    let orderItems: [OrderItem]
    let orderRevenue: Float?
    let orderSubTotal: Float?
    let orderTax: Float?
    let orderShippingCost: Float?
    let orderDiscount: Float?
    let orderLastDate: Date?

}

extension Event {
    public init(tracker: MatomoTracker, action: [String], url: URL? = nil, referer: URL? = nil, eventCategory: String? = nil, eventAction: String? = nil, eventName: String? = nil, eventValue: Float? = nil, customTrackingParameters: [String:String] = [:], searchQuery: String? = nil, searchCategory: String? = nil, searchResultsCount: Int? = nil, dimensions: [CustomDimension] = [], variables: [CustomVariable] = [], contentName: String? = nil, contentInteraction: String? = nil, contentPiece: String? = nil, contentTarget: String? = nil, goalId: Int? = nil, revenue: Float? = nil, orderId: String? = nil, orderItems: [OrderItem] = [], orderRevenue: Float? = nil, orderSubTotal: Float? = nil, orderTax: Float? = nil, orderShippingCost: Float? = nil, orderDiscount: Float? = nil, orderLastDate: Date? = nil) {
        self.siteId = tracker.siteId
        self.uuid = NSUUID()
        self.visitor = tracker.visitor
        self.session = tracker.session
        self.date = Date()
        self.url = url ?? tracker.contentBase?.appendingPathComponent(action.joined(separator: "/"))
        self.actionName = action
        self.language = Locale.httpAcceptLanguage
        self.isNewSession = tracker.nextEventStartsANewSession
        self.referer = referer
        self.eventCategory = eventCategory
        self.eventAction = eventAction
        self.eventName = eventName
        self.eventValue = eventValue
        self.searchQuery = searchQuery
        self.searchCategory = searchCategory
        self.searchResultsCount = searchResultsCount
        self.dimensions = tracker.dimensions + dimensions
        self.campaignName = tracker.campaignName
        self.campaignKeyword = tracker.campaignKeyword
        self.customTrackingParameters = customTrackingParameters
        self.customVariables = tracker.customVariables + variables
        self.contentName = contentName
        self.contentPiece = contentPiece
        self.contentTarget = contentTarget
        self.contentInteraction = contentInteraction
        self.goalId = goalId
        self.revenue = revenue
        self.orderId = orderId
        self.orderItems = orderItems
        self.orderRevenue = orderRevenue
        self.orderSubTotal = orderSubTotal
        self.orderTax = orderTax
        self.orderShippingCost = orderShippingCost
        self.orderDiscount = orderDiscount
        self.orderLastDate = orderLastDate
    }
}

//MARK: Optimove
extension Event
{
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: JsonCodingKeys.self)
        siteId = try values.decode(String.self, forKey: .siteId)
        uuid = NSUUID(uuidString: try values.decode(String.self, forKey: .uuid))!
        visitor = try values.decode(Visitor.self, forKey: .visitor)
        session = try values.decode(Session.self, forKey: .session)
        date = try values.decode(Date.self, forKey: .date)

        if let urlPath = try? values.decode(String.self, forKey: .url).removingPercentEncoding {
            url = URL(string: urlPath!)
        } else {
            url = nil
        }
        actionName = try values.decode([String].self, forKey: .actionName)
        language = try values.decode(String.self, forKey: .language)
        isNewSession = try values.decode(Bool.self, forKey: .isNewSession)
        if let urlPath = try? values.decode(String.self, forKey: .referer).removingPercentEncoding {
            referer = URL(string: urlPath!)
        } else {
            referer = nil
        }
        screenResolution  = try values.decode(CGSize.self, forKey: .screenResolution)
        customVariables = try values.decode([CustomVariable].self, forKey: .customVariables)
        eventCategory = try? values.decode(String.self, forKey: .eventCategory)
        eventAction = try? values.decode(String.self, forKey: .eventAction)
        eventName = try? values.decode(String.self, forKey: .eventName)
        eventValue = try? values.decode(Float.self, forKey: .eventValue)

        campaignName = try? values.decode(String.self, forKey: .campaignName)
        campaignKeyword = try? values.decode(String.self, forKey: .campaignKeyword)

        searchQuery = try? values.decode(String.self, forKey: .searchQuery)
        searchCategory = try? values.decode(String.self, forKey: .searchCategory)
        searchResultsCount = try? values.decode(Int.self, forKey: .searchResultsCount)

        dimensions = try values.decode([CustomDimension].self, forKey: .dimensions)
        customTrackingParameters = try values.decode([String:String].self, forKey: .customTrackingParameters)

        contentName = try? values.decode(String.self, forKey: .contentName)
        contentPiece = try? values.decode(String.self, forKey: .contentPiece)
        contentTarget = try? values.decode(String.self, forKey: .contentTarget)
        contentInteraction = try? values.decode(String.self, forKey: .contentInteraction)


        goalId = try? values.decode(Int.self, forKey: .goalId)
        revenue = try? values.decode(Float.self, forKey: .revenue)


        orderId = try? values.decode(String.self, forKey: .orderId)
        orderItems = try values.decode([OrderItem].self, forKey: .orderItems) 
        orderRevenue = try? values.decode(Float.self, forKey: .orderRevenue)
        orderSubTotal = try? values.decode(Float.self, forKey: .orderSubTotal)
        orderTax = try? values.decode(Float.self, forKey: .orderTax)
        orderShippingCost = try? values.decode(Float.self, forKey: .orderShippingCost)
        orderDiscount = try? values.decode(Float.self, forKey: .orderDiscount)
        orderLastDate = try? values.decode(Date.self, forKey: .orderLastDate)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: JsonCodingKeys.self)
        try container.encode(siteId, forKey: .siteId)
        try container.encode(uuid.uuidString, forKey: .uuid)
        try container.encode(visitor, forKey: .visitor)
        try container.encode(session, forKey: .session)
        try container.encode(date, forKey: .date)
        try container.encode(url, forKey: .url)
        try container.encode(actionName, forKey: .actionName)
        try container.encode(language, forKey: .language)
        try container.encode(isNewSession, forKey: .isNewSession)
        try container.encode(referer, forKey: .referer)
        try container.encode(screenResolution, forKey: .screenResolution)
        try container.encode(customVariables, forKey: .customVariables)
        try container.encode(eventCategory, forKey: .eventCategory)
        try container.encode(eventAction, forKey: .eventAction)
        try container.encode(eventName, forKey: .eventName)
        try container.encode(eventValue, forKey: .eventValue)
        try container.encode(campaignName, forKey: .campaignName)
        try container.encode(campaignKeyword, forKey: .campaignKeyword)
        try container.encode(searchQuery, forKey: .searchQuery)
        try container.encode(searchCategory, forKey: .searchCategory)
        try container.encode(searchResultsCount, forKey: .searchResultsCount)

        try container.encode(dimensions, forKey: .dimensions)
        try container.encode(customTrackingParameters, forKey: .customTrackingParameters)

        try container.encode(contentName, forKey: .contentName)
        try container.encode(contentPiece, forKey: .contentPiece)
        try container.encode(contentTarget, forKey: .contentTarget)
        try container.encode(contentInteraction, forKey: .contentInteraction)
        try container.encode(goalId, forKey: .goalId)
        try container.encode(revenue, forKey: .revenue)
        try container.encode(orderId, forKey: .orderId)
        try container.encode(orderItems, forKey: .orderItems)
        try container.encode(orderRevenue, forKey: .orderRevenue)
        try container.encode(orderSubTotal, forKey: .orderSubTotal)
        try container.encode(orderTax, forKey: .orderTax)
        try container.encode(orderShippingCost, forKey: .orderShippingCost)
        try container.encode(orderDiscount, forKey: .orderDiscount)
        try container.encode(orderLastDate, forKey: .orderLastDate)
    }
    enum JsonCodingKeys: String,CodingKey
    {
        case siteId
        case uuid
        case visitor
        case session
        case date
        case url
        case actionName
        case language
        case isNewSession
        case referer
        case screenResolution
        case customVariables
        case eventCategory
        case eventAction
        case eventName
        case eventValue
        case campaignName
        case campaignKeyword
        case searchQuery
        case searchCategory
        case searchResultsCount
        case dimensions
        case customTrackingParameters
        case contentName
        case contentPiece
        case contentTarget
        case contentInteraction
        case goalId
        case revenue
        case orderId
        case orderItems
        case orderRevenue
        case orderSubTotal
        case orderTax
        case orderShippingCost
        case orderDiscount
        case orderLastDate
    }
}
