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
    static let showLabels = Key<Bool>("showLabels", default: true)
    
    static let refreshRate = Key<Int>("refreshRate", default: 5)
    static let buildType = Key<BuildType>("buildType", default: .none)
    static let counterType = Key<CounterType>("counterType", default: .reviewRequested)
}

extension KeychainKeys {
    static let githubToken: KeychainAccessKey = KeychainAccessKey(key: "githubToken")
}

enum BuildType: String, Defaults.Serializable, CaseIterable, Identifiable {
    case checks
    case commitStatus
    case none
    
    var id: Self { self }

    var description: String {

        switch self {
        case .checks:
            return "checks"
        case .commitStatus:
            return "commit statuses"
        case .none:
            return "none"
        }
    }
}

enum CounterType: String, Defaults.Serializable, CaseIterable, Identifiable {
    case assigned
    case created
    case reviewRequested
    case none
    
    var id: Self { self }

    var description: String {

        switch self {
        case .assigned:
            return "assigned"
        case .created:
            return "created"
        case .reviewRequested:
            return "review requested"
        case .none:
            return "none"
        }
    }
}
