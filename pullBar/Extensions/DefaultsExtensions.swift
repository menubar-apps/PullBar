//
//  DefaultsExtensions.swift
//  pullBar
//
//  Created by Pavel Makhov on 2021-11-10.
//

import Foundation
import Defaults

extension Defaults.Keys {
    static let bitbucketBaseUrl = Key<String>("bitbucketBaseUrl", default: "https://bitbucket.example.com")

    /// Ordered list of categories shown in the menubar menu. Order determines
    /// the order sections appear.
    static let categories = Key<[SearchCategory]>("categories", default: SearchCategory.defaultCategories)
    static let categoriesSchemaVersion = Key<Int>("categoriesSchemaVersion", default: 0)

    static let showAvatar = Key<Bool>("showAvatar", default: false)
    static let showLabels = Key<Bool>("showLabels", default: true)

    static let refreshRate = Key<Int>("refreshRate", default: 5)
    static let buildType = Key<BuildType>("buildType", default: .none)
    // Which count is shown next to the menubar icon: the id of a category, or
    // `counterNone`.
    static let counterSelection = Key<String>("counterSelection", default: BuiltinTemplate.incoming.seedId)
}

extension KeychainKeys {
    static let bitbucketToken: KeychainAccessKey = KeychainAccessKey(key: "bitbucketToken")
    static let bitbucketUsername: KeychainAccessKey = KeychainAccessKey(key: "bitbucketUsername")
    // Legacy GitHub token, referenced only so it can be removed during the
    // Bitbucket migration.
    static let githubToken: KeychainAccessKey = KeychainAccessKey(key: "githubToken")
}

/// A named Bitbucket pull-request role that becomes a section in the menu.
/// Bitbucket Data Center filters pull requests by the viewer's role rather than
/// a free-text search query.
struct SearchCategory: Codable, Defaults.Serializable, Identifiable, Hashable {
    var id: String
    var name: String
    var role: BitbucketRole
    var asSubmenu: Bool

    init(id: String, name: String, role: BitbucketRole, asSubmenu: Bool = false) {
        self.id = id
        self.name = name
        self.role = role
        self.asSubmenu = asSubmenu
    }

    // Custom decoding so categories stored by older versions still decode
    // rather than failing and wiping the user's saved list. The pre-Bitbucket
    // model stored a `filter` and no `role`, so a missing/unknown role falls
    // back to `.all` while preserving the category's name and id.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        role = (try? container.decode(BitbucketRole.self, forKey: .role)) ?? .all
        asSubmenu = try container.decodeIfPresent(Bool.self, forKey: .asSubmenu) ?? false
    }

    var displayName: String {
        name.isEmpty ? role.displayName : name
    }

    // MARK: - Counter selection tokens

    /// No count shown next to the menubar icon.
    static let counterNone = ""

    // MARK: - Defaults

    /// The list a fresh install starts with, matching the previous default of
    /// showing only review requests.
    static let defaultCategories: [SearchCategory] = [
        BuiltinTemplate.incoming.makeSeedCategory(),
    ]
}

/// Predefined role-based starting points offered by the "+" menu on the
/// Categories tab. Once added they become ordinary categories the user can
/// rename.
enum BuiltinTemplate: String, CaseIterable, Identifiable {
    case incoming
    case authored
    case all

    var id: String { rawValue }

    var role: BitbucketRole {
        switch self {
        case .incoming: return .incoming
        case .authored: return .authored
        case .all: return .all
        }
    }

    var name: String { role.displayName }

    /// Stable id used for categories created by the defaults.
    var seedId: String {
        switch self {
        case .incoming: return "seed-incoming"
        case .authored: return "seed-authored"
        case .all: return "seed-all"
        }
    }

    func makeCategory(id: String) -> SearchCategory {
        SearchCategory(id: id, name: name, role: role)
    }

    func makeSeedCategory() -> SearchCategory {
        makeCategory(id: seedId)
    }
}

enum BitbucketRole: String, Codable, Hashable, CaseIterable, Identifiable {
    case incoming = "incoming"
    case authored = "authored"
    case all = "all"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .incoming: return "Incoming"
        case .authored: return "Created By Me"
        case .all: return "All"
        }
    }

    /// Value for the dashboard endpoint's `role` query parameter. Bitbucket DC
    /// exposes a single `dashboard/pull-requests` resource filtered by role;
    /// `nil` means no role filter (PRs the user is involved in, in any role).
    var dashboardRole: String? {
        switch self {
        case .incoming: return "REVIEWER"
        case .authored: return "AUTHOR"
        case .all: return nil
        }
    }
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