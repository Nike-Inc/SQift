//
//  ProcessInfoExtension.swift
//
//  Copyright 2015-present, Nike, Inc.
//  All rights reserved.
//
//  This source code is licensed under the BSD-stylelicense found in the LICENSE
//  file in the root directory of this source tree.
//

import Foundation

extension ProcessInfo {
    private enum EnvironmentVariable: String {
        case runningOnCI = "RUNNING_ON_CI"
    }

    static var isRunningOnCI: Bool {
        guard let value = processInfo.environment[EnvironmentVariable.runningOnCI.rawValue] else { return false }
        return value == "YES"
    }
}
