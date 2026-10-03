//
//  DefaultsExtensions.swift
//  issueBar
//
//  Created by Pavel Makhov on 2021-11-10.
//

import Foundation
import Defaults

extension Defaults.Keys {
    static let githubApiBaseUrl = Key<String>("githubApiBaseUrl", default: "https://api.github.com")
    static let githubUsername = Key<String>("githubUsername", default: "")
    static let githubAdditionalQuery = Key<String>("githubAdditionalQuery", default:"")

    // Legacy keys, kept only so preferences from older versions can be migrated
    // into `categories` / `counterSelection`.
    static let showAssigned = Key<Bool>("showAssigned", default: false)
    static let showCreated = Key<Bool>("showCreated", default: false)
    static let showRequested = Key<Bool>("showRequested", default: true)
    static let legacyCounterType = Key<String>("counterType", default: "reviewRequested")

    // Ordered list of categories the user has added. Order determines the order
    // sections appear in the menubar menu.
    static let categories = Key<[SearchCategory]>("categories", default: SearchCategory.defaultCategories)
    // Bumped when the categories storage format changes so migrations run once.
    static let categoriesSchemaVersion = Key<Int>("categoriesSchemaVersion", default: 0)

    static let showAvatar = Key<Bool>("showAvatar", default: false)
    static let showLabels = Key<Bool>("showLabels", default: true)

    static let refreshRate = Key<Int>("refreshRate", default: 5)
    static let buildType = Key<BuildType>("buildType", default: .none)
    // Which count is shown next to the menubar icon. Either a special token
    // (`counterNone` / `counterMyTeam`) or the id of a category.
    static let counterSelection = Key<String>("counterSelection", default: SearchCategory.counterMyTeam)
}

extension KeychainKeys {
    static let githubToken: KeychainAccessKey = KeychainAccessKey(key: "githubToken")
}

/// A named GitHub search that becomes a section in the menu. Categories are added
/// by the user (optionally seeded from a builtin template) and are freely
/// editable, reorderable, and deletable.
struct SearchCategory: Codable, Defaults.Serializable, Identifiable, Hashable {
    var id: String
    var name: String
    var filter: String
    /// When true the category renders as a single collapsible menu item
    /// ("Name (12) ▸") whose submenu holds the pull requests, instead of listing
    /// them inline.
    var asSubmenu: Bool

    init(id: String, name: String, filter: String, asSubmenu: Bool = false) {
        self.id = id
        self.name = name
        self.filter = filter
        self.asSubmenu = asSubmenu
    }

    // Custom decoding so categories stored before `asSubmenu` existed still
    // decode (missing key defaults to false) rather than failing and wiping the
    // user's saved list.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        filter = try container.decode(String.self, forKey: .filter)
        asSubmenu = try container.decodeIfPresent(Bool.self, forKey: .asSubmenu) ?? false
    }

    /// Placeholder in a filter that is replaced with the configured username at
    /// query time. Not GitHub search syntax — used so a template filter can be
    /// stored statically while still resolving to the current user.
    static let usernamePlaceholder = "<username>"

    /// The search filter to actually query with. The `<username>` placeholder is
    /// replaced with the configured username; everything else is passed through
    /// verbatim, so raw GitHub search syntax (including a literal `@me`) in a
    /// custom filter is left untouched.
    func resolvedFilter(username: String) -> String {
        filter.replacingOccurrences(of: SearchCategory.usernamePlaceholder, with: username)
    }

    // MARK: - Counter selection tokens

    /// No count shown next to the menubar icon.
    static let counterNone = ""
    /// Count of team review requests, independent of the categories list.
    static let counterMyTeam = "__my_team__"
    /// Filter backing the "My team" counter option.
    static let myTeamFilter = "review-requested:\(usernamePlaceholder)"

    // MARK: - Defaults

    /// The list a fresh install starts with: the original three builtin types.
    static let defaultCategories: [SearchCategory] = [
        BuiltinTemplate.assigned.makeCategory(id: "seed-assigned"),
        BuiltinTemplate.created.makeCategory(id: "seed-created"),
        BuiltinTemplate.reviewRequested.makeCategory(id: "seed-review-requested"),
    ]
}

/// Predefined starting points offered by the "+" menu on the Categories tab.
/// Once added they become ordinary categories the user can rename or re-query.
enum BuiltinTemplate: String, CaseIterable, Identifiable {
    case assigned
    case created
    case reviewRequested
    case userReviewRequested

    var id: String { rawValue }

    var name: String {
        switch self {
        case .assigned: return "Assigned"
        case .created: return "Created"
        case .reviewRequested: return "Review Requested"
        case .userReviewRequested: return "Review Requested (Direct)"
        }
    }

    var filter: String {
        switch self {
        case .assigned: return "assignee:\(SearchCategory.usernamePlaceholder)"
        case .created: return "author:\(SearchCategory.usernamePlaceholder)"
        case .reviewRequested: return "review-requested:\(SearchCategory.usernamePlaceholder)"
        case .userReviewRequested: return "user-review-requested:\(SearchCategory.usernamePlaceholder)"
        }
    }

    func makeCategory(id: String) -> SearchCategory {
        SearchCategory(id: id, name: name, filter: filter)
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
