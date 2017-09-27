//
//  ProcessInfoExtension.swift
//  SQift
//
//  Created by Christian Noon on 9/21/17.
//  Copyright © 2017 Nike. All rights reserved.
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
