//  Copyright © 2019 Optimove. All rights reserved.

/// The internal event used for this share type between modules via OptimoveCore.
/// TODO: Change `parameters` value type from `Any` to a custom type,
/// and do casting on the first input of `OptimoveEvent`.
public protocol OptimoveEventInternal {
    var name: String { get }
    var parameters: [String: Any] { get }
}
