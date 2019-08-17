//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public typealias ResultBlock = () -> Void
public typealias ResultBlockWithError = (OptimoveError?) -> Void
public typealias ResultBlockWithErrors = ([OptimoveError]) -> Void
public typealias ResultBlockWithBool = (Bool) -> Void
public typealias ResultBlockWithData = (Data?, OptimoveError?) -> Void
