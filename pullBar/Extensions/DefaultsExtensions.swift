//
//  DefaultsExtensions.swift
//  issueBar
//
//  Created by Pavel Makhov on 2021-11-10.
//

import Foundation
import Defaults

extension Defaults.Keys {
    static let githubUsername = Key<String>("githubUsername", default: "")
    
    static let showAssigned = Key<Bool>("showAssigned", default: false)
    static let showCreated = Key<Bool>("showCreated", default: false)
    static let showRequested = Key<Bool>("showRequested", default: true)
    
    static let showAvatar = Key<Bool>("showAvatar", default: false)
    static let showChecks = Key<Bool>("showChecks", default: true)
    static let showLabels = Key<Bool>("showLabels", default: true)
    
    static let refreshRate = Key<Int>("refreshRate", default: 5)
}

extension KeychainKeys {
    static let githubToken: KeychainAccessKey = KeychainAccessKey(key: "githubToken")
}
