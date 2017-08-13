//
//  DispatchQueueExtension.swift
//  SQift
//
//  Created by Christian Noon on 8/13/17.
//  Copyright © 2017 Nike. All rights reserved.
//

import Foundation

extension DispatchQueue {
    static let userInteractive = DispatchQueue.global(qos: .userInteractive)
    static let userInitiated = DispatchQueue.global(qos: .userInitiated)
    static let utility = DispatchQueue.global(qos: .utility)
    static let background = DispatchQueue.global(qos: .background)
}
