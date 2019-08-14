//
//  CwlMutex.swift
//  CwlUtils
//
//  Created by Matt Gallagher on 2015/02/03.
//  Copyright © 2015 Matt Gallagher ( https://www.cocoawithlove.com ). All rights reserved.
//
//  Permission to use, copy, modify, and/or distribute this software for any
//  purpose with or without fee is hereby granted, provided that the above
//  copyright notice and this permission notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
//  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
//  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
//  SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
//  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
//  IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//

#if os(Linux)
import Glibc
#else
import Darwin
#endif

/// A basic mutex protocol that requires nothing more than "performing work inside the mutex".
protocol ScopedMutex {
    /// Perform work inside the mutex
    func sync<R>(execute work: () throws -> R) rethrows -> R

    /// Perform work inside the mutex, returning immediately if the mutex is in-use
    func trySync<R>(execute work: () throws -> R) rethrows -> R?
}

/// A more specific kind of mutex that assume an underlying primitive and unbalanced lock/trylock/unlock operators
protocol RawMutex: ScopedMutex {
    associatedtype MutexPrimitive

    var underlyingMutex: MutexPrimitive { get set }

    func unbalancedLock()
    func unbalancedTryLock() -> Bool
    func unbalancedUnlock()
}

extension RawMutex {
    func sync<R>(execute work: () throws -> R) rethrows -> R {
        unbalancedLock()
        defer { unbalancedUnlock() }
        return try work()
    }
    func trySync<R>(execute work: () throws -> R) rethrows -> R? {
        guard unbalancedTryLock() else { return nil }
        defer { unbalancedUnlock() }
        return try work()
    }
}

/// A basic wrapper around `os_unfair_lock` (a non-FIFO, high performance lock that offers safety against priority inversion). This type is a "class" type to prevent accidental copying of the `os_unfair_lock`.
@available(OSX 10.12, iOS 10, tvOS 10, watchOS 3, *)
final class UnfairLock: RawMutex {
    typealias MutexPrimitive = os_unfair_lock

    init() {
    }

    /// Exposed as an "unsafe" property so non-scoped patterns can be implemented, if required.
    var underlyingMutex = os_unfair_lock()

    func unbalancedLock() {
        os_unfair_lock_lock(&underlyingMutex)
    }

    func unbalancedTryLock() -> Bool {
        return os_unfair_lock_trylock(&underlyingMutex)
    }

    func unbalancedUnlock() {
        os_unfair_lock_unlock(&underlyingMutex)
    }
}
