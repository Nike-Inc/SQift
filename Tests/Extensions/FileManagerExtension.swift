//
//  FileManagerExtension.swift
//  SQift
//
//  Created by Christian Noon on 11/8/15.
//  Copyright © 2015 Nike. All rights reserved.
//

import Foundation

extension FileManager {
    static var documentsDirectory: String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    }

    static var cachesDirectory: String {
        return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
    }

    static func removeItem(atPath path: String) {
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch {
            // No-op
        }
    }
}
