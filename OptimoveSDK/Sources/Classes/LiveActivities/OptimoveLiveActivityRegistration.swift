//  Copyright © 2026 Optimove. All rights reserved.

import Foundation

#if canImport(ActivityKit)
    import ActivityKit
#endif

/// Host `ActivityAttributes` must include Optimove's activity id.
/// Conform in the app target, not the widget extension.
public protocol OptimoveLiveActivityAttributes {
    /// Id stamped on the Optimove start payload. `nil` if Optimove did not start this activity.
    var optimoveActivityId: String? { get }
}

/// Type-erased `ActivityAttributes` type stored on `OptimoveConfig`.
struct OptimoveLiveActivityRegistration {
    let attributesTypeName: String

    let observe: (OptimoveLiveActivities) -> Void
}

#if canImport(ActivityKit)
    extension OptimoveLiveActivityRegistration {
        @available(iOS 18.0, *)
        init<Attributes: ActivityAttributes & OptimoveLiveActivityAttributes>(_ type: Attributes.Type) {
            attributesTypeName = String(describing: type)
            observe = { manager in
                manager.observe(Attributes.self)
            }
        }
    }
#endif
