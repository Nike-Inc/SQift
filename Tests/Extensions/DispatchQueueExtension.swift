//
//  DispatchQueueExtension.swift
//
//  Copyright 2015-present, Nike, Inc.
//  All rights reserved.
//
//  This source code is licensed under the BSD-stylelicense found in the LICENSE
//  file in the root directory of this source tree.
//

import Foundation

extension DispatchQueue {
    static let userInteractive = DispatchQueue.global(qos: .userInteractive)
    static let userInitiated = DispatchQueue.global(qos: .userInitiated)
    static let utility = DispatchQueue.global(qos: .utility)
    static let background = DispatchQueue.global(qos: .background)
}

// MARK: -

extension DispatchQueue {
    func asyncAfter(seconds: TimeInterval, execute closure: @escaping () -> Void) {
        asyncAfter(deadline: .now() + seconds, execute: closure)
    }
}
