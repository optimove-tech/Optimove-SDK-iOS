/*
 MIT License

 Copyright (c) 2017 Tomáš Znamenáček

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import Foundation

extension JSON {
    /// Return a new JSON value by merging two other ones
    ///
    /// If we call the current JSON value `old` and the incoming JSON value
    /// `new`, the precise merging rules are:
    ///
    /// 1. If `old` or `new` are anything but an object, return `new`.
    /// 2. If both `old` and `new` are objects, create a merged object like this:
    ///     1. Add keys from `old` not present in `new` (“no change” case).
    ///     2. Add keys from `new` not present in `old` (“create” case).
    ///     3. For keys present in both `old` and `new`, apply merge recursively to their values (“update” case).
    func merging(with new: JSON) -> JSON {
        // If old or new are anything but an object, return new.
        guard case let .object(lhs) = self, case let .object(rhs) = new else {
            return new
        }

        var merged: [String: JSON] = [:]

        // Add keys from old not present in new (“no change” case).
        for (key, val) in lhs where rhs[key] == nil {
            merged[key] = val
        }

        // Add keys from new not present in old (“create” case).
        for (key, val) in rhs where lhs[key] == nil {
            merged[key] = val
        }

        // For keys present in both old and new, apply merge recursively to their values.
        for key in lhs.keys where rhs[key] != nil {
            merged[key] = lhs[key]?.merging(with: rhs[key]!)
        }

        return JSON.object(merged)
    }
}
