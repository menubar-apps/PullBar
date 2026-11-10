//
//  AppDelegate.swift
//  pullBar
//
//  Created by Pavel Makhov on 2021-11-15.
//

import Cocoa
import Defaults
import SwiftUI
import Foundation
import KeychainAccess

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @FromKeychain(.githubToken) var githubToken
    
    let ghClient = GitHubClient()
    var statusBarItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let menu: NSMenu = NSMenu()
    
    var preferencesWindow: NSWindow!
    var aboutWindow: NSWindow!
    
    var timer: Timer? = nil
    private var loadingIndicator: NSProgressIndicator?
    private weak var refreshButton: NSButton?
    private let refreshItemTag = 902
    private var refreshGeneration = 0
    private var reviewURLs = Set<URL>()
    private var displayedPRURLs = Set<URL>()

    private func lastRead(for pull: Pull) -> Date? {
        UserDefaults.standard.object(forKey: "reviewRead:" + pull.url.absoluteString) as? Date
    }

    private func reasons(for pull: Pull) -> [String] {
        pull.actionReasons(lastRead: lastRead(for: pull))
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        migrateCategoriesIfNeeded()

        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.windowClosed), name: NSWindow.willCloseNotification, object: nil)

        guard let statusButton = statusBarItem.button else { return }
        let icon = NSImage(named: "git-pull-request")
        let size = NSSize(width: 16, height: 16)
        icon?.isTemplate = true
        icon?.size = size
        statusButton.image = icon
        statusButton.imagePosition = NSControl.ImagePosition.imageLeft
        updateStatusCounter(0)
        
        statusBarItem.menu = menu
        
        timer = Timer.scheduledTimer(
            timeInterval: Double(Defaults[.refreshRate] * 60),
            target: self,
            selector: #selector(refreshMenu),
            userInfo: nil,
            repeats: true
        )
        timer?.fire()
        RunLoop.main.add(timer!, forMode: .common)
        NSApp.setActivationPolicy(.accessory)


        // Insert code here to initialize your application
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    @objc
    func openLink(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        if NSWorkspace.shared.open(url), displayedPRURLs.contains(url) {
            UserDefaults.standard.set(Date(), forKey: "reviewRead:" + url.absoluteString)
            refreshMenu()
        }
    }

    func migrateCategoriesIfNeeded() {
        if Defaults[.categoriesSchemaVersion] < 1 {
            Defaults[.categoriesSchemaVersion] = 1
            migrateLegacyCategories()
        }
        // Filters used to store a `<username>` placeholder; GitHub search resolves `@me` itself.
        if Defaults[.categoriesSchemaVersion] < 2 {
            Defaults[.categoriesSchemaVersion] = 2
            Defaults[.categories] = Defaults[.categories].map {
                var category = $0
                category.filter = category.filter.replacingOccurrences(of: "<username>", with: "@me")
                return category
            }
        }
        // The global "Additional Query" setting was appended to every search; move it into each filter.
        if Defaults[.categoriesSchemaVersion] < 3 {
            Defaults[.categoriesSchemaVersion] = 3
            let additionalQuery = Defaults[.legacyAdditionalQuery].trimmingCharacters(in: .whitespacesAndNewlines)
            if !additionalQuery.isEmpty {
                Defaults[.categories] = Defaults[.categories].map {
                    var category = $0
                    category.filter = "\(category.filter) \(additionalQuery)"
                    return category
                }
            }
            Defaults.reset(.legacyAdditionalQuery)
        }
    }

    /// One-time migration of the legacy per-type toggles and counter choice into
    /// the user-managed `categories` list and `counterSelection`. Fresh installs
    /// (no persisted legacy settings) keep the default categories instead.
    private func migrateLegacyCategories() {
        let userDefaults = UserDefaults.standard
        let hasLegacySettings = ["showAssigned", "showCreated", "showRequested", "counterType"]
            .contains { userDefaults.object(forKey: $0) != nil }
        guard hasLegacySettings else { return }

        let counterTemplate: BuiltinTemplate?
        switch Defaults[.legacyCounterType] {
        case "none": counterTemplate = nil
        case "assigned": counterTemplate = .assigned
        case "created": counterTemplate = .created
        default: counterTemplate = .reviewRequested
        }

        // Seed the categories list from the legacy toggles, preserving order. A
        // counter that pointed at a hidden section adds that section, since the
        // counter can only show a category's count.
        let enabled: [BuiltinTemplate: Bool] = [
            .assigned: Defaults[.showAssigned],
            .created: Defaults[.showCreated],
            .reviewRequested: Defaults[.showRequested],
        ]
        let seeded = [BuiltinTemplate.assigned, .created, .reviewRequested]
            .filter { enabled[$0] == true || $0 == counterTemplate }
        Defaults[.categories] = seeded.map { $0.makeSeedCategory() }
        Defaults[.counterSelection] = counterTemplate?.seedId ?? SearchCategory.counterNone
    }

    @objc
    func copyLink(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.absoluteString, forType: .string)
    }

}

extension AppDelegate {
    /// Colored attachments leave the original menu bar icon adaptive to macOS.
    private func counterBadge(_ count: Int, color: NSColor, textColor: NSColor = .white) -> NSAttributedString {
        let text = NSAttributedString(string: String(count), attributes: [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .bold),
            .foregroundColor: textColor,
        ])
        let textSize = text.size()
        let size = NSSize(width: max(18, ceil(textSize.width) + 10), height: 18)
        let badge = NSImage(size: size, flipped: false) { rect in
            color.setFill()
            NSBezierPath(roundedRect: rect, xRadius: 9, yRadius: 9).fill()
            text.draw(at: NSPoint(x: (rect.width - textSize.width) / 2, y: (rect.height - textSize.height) / 2))
            return true
        }
        badge.isTemplate = false
        let attachment = NSTextAttachment()
        attachment.image = badge
        attachment.bounds = NSRect(x: 0, y: -4, width: size.width, height: size.height)
        return NSAttributedString(attachment: attachment)
    }

    private func personalActionIcon(readyToMerge: Bool) -> NSAttributedString {
        let symbol = NSImage(systemSymbolName: readyToMerge ? "person.fill" : "person",
                             accessibilityDescription: nil)
        symbol?.size = NSSize(width: 16, height: 16)
        let image = symbol?.tint(color: readyToMerge ? .systemGreen : .labelColor)
        image?.isTemplate = false
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = NSRect(x: 0, y: -3, width: 16, height: 16)
        return NSAttributedString(attachment: attachment)
    }

    func updateStatusCounter(_ reviews: Int, actions: Int = 0, readyToMergeCount: Int = 0) {
        stopStatusLoading()
        guard let button = statusBarItem.button else { return }
        let title = NSMutableAttributedString(string: "")
        if reviews > 0 { title.append(counterBadge(reviews, color: .systemRed)) }
        if actions > 0 {
            if reviews > 0 { title.append(NSAttributedString(string: " ")) }
            title.append(personalActionIcon(readyToMerge: readyToMergeCount > 0))
            title.append(NSAttributedString(string: " "))
            title.append(NSAttributedString(string: String(actions), attributes: [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold),
                .foregroundColor: NSColor.labelColor,
            ]))
        }
        button.title = ""
        button.attributedTitle = title
        let summary = Defaults[.actionDashboard]
            ? "\(reviews) PRs to review · \(actions) of your PRs need action · \(readyToMergeCount) ready to merge"
            : "\(reviews) pull requests"
        button.toolTip = summary
        button.setAccessibilityLabel("PullBar")
        button.setAccessibilityValue(summary)
    }

    private func startStatusLoading() {
        guard let button = statusBarItem.button else { return }
        stopStatusLoading()
        button.title = ""
        button.attributedTitle = NSAttributedString(string: "    ")
        statusBarItem.length = 48
        button.toolTip = "Refreshing pull requests…"
        button.setAccessibilityValue("Loading pull requests")
        let indicator = StatusLoadingIndicator()
        indicator.style = .spinning
        indicator.controlSize = .small
        indicator.isIndeterminate = true
        indicator.isDisplayedWhenStopped = false
        indicator.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -5),
            indicator.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            indicator.widthAnchor.constraint(equalToConstant: 16),
            indicator.heightAnchor.constraint(equalToConstant: 16),
        ])
        indicator.startAnimation(nil)
        loadingIndicator = indicator
        refreshButton?.title = "Refreshing…"
        refreshButton?.isEnabled = false
    }

    private func stopStatusLoading() {
        loadingIndicator?.stopAnimation(nil)
        loadingIndicator?.removeFromSuperview()
        loadingIndicator = nil
        refreshButton?.title = "Refresh"
        refreshButton?.isEnabled = true
        statusBarItem.length = NSStatusItem.variableLength
    }

    @objc
    func refreshMenu() {
        refreshGeneration += 1
        let generation = refreshGeneration
        guard !githubToken.isEmpty else {
            menu.removeAllItems()
            reviewURLs.removeAll()
            displayedPRURLs.removeAll()
            updateStatusCounter(0)
            menu.addItem(withTitle: "Set your GitHub token in Preferences", action: nil, keyEquivalent: "")
            addMenuFooterItems()
            return
        }
        let token = githubToken
        startStatusLoading()
        let dashboard = Defaults[.actionDashboard]
        let categories = dashboard ? [
            SearchCategory(id: "reviews", name: "To review", filter: "review-requested:@me -author:@me"),
            SearchCategory(id: "mine", name: "My PRs", filter: "author:@me"),
        ] : Defaults[.categories].filter { !$0.filter.trimmingCharacters(in: .whitespaces).isEmpty }
        var results: [String: [Edge]] = [:]
        var fetchError: Error?
        let group = DispatchGroup()
        if menu.items.isEmpty {
            menu.addItem(withTitle: "Loading pull requests…", action: nil, keyEquivalent: "")
            addMenuFooterItems()
        }
        for category in categories {
            group.enter()
            ghClient.getPulls(filter: category.filter) { result in
                switch result {
                case .success(let pulls): results[category.id] = pulls
                case .failure(let error): fetchError = error
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            guard generation == self.refreshGeneration else { return }
            self.stopStatusLoading()
            guard token == self.githubToken else {
                self.refreshMenu()
                return
            }
            if let error = fetchError {
                // Keep the last successful list, but never present stale counters as current.
                if let oldError = self.menu.item(withTag: 901) { self.menu.removeItem(oldError) }
                let item = NSMenuItem(title: "Refresh failed — previous results may be outdated", action: nil, keyEquivalent: "")
                item.tag = 901
                item.toolTip = error.localizedDescription
                self.menu.insertItem(item, at: 0)
                self.statusBarItem.button?.attributedTitle = NSAttributedString(string: "!")
                self.statusBarItem.button?.toolTip = "Refresh failed: " + error.localizedDescription
                self.statusBarItem.button?.setAccessibilityValue("Refresh failed")
                return
            }
            let updatedMenu = NSMenu()
            self.reviewURLs = Set((results["reviews"] ?? []).map { $0.node.url })
            self.displayedPRURLs = Set(results.values.flatMap { $0 }.map { $0.node.url })
            for category in categories {
                var pulls = results[category.id] ?? []
                if dashboard {
                    pulls.sort {
                        let left = !self.reasons(for: $0.node).isEmpty
                        let right = !self.reasons(for: $1.node).isEmpty
                        if category.id == "mine", left != right { return left }
                        return $0.node.createdAt < $1.node.createdAt
                    }
                }
                guard dashboard || !pulls.isEmpty else { continue }
                let header = "\(category.displayName) (\(pulls.count))"
                let target: NSMenu
                if category.asSubmenu {
                    let parent = NSMenuItem(title: header, action: nil, keyEquivalent: "")
                    target = NSMenu()
                    parent.submenu = target
                    updatedMenu.addItem(parent)
                } else {
                    updatedMenu.addItem(withTitle: header, action: nil, keyEquivalent: "")
                    target = updatedMenu
                }
                if pulls.isEmpty { target.addItem(withTitle: "No open PRs", action: nil, keyEquivalent: "") }
                for pull in pulls { self.addMenuItems(pull: pull, to: target) }
                updatedMenu.addItem(.separator())
            }
            if dashboard {
                let ownPulls = results["mine"] ?? []
                let actions = ownPulls.filter { !self.reasons(for: $0.node).isEmpty }.count
                let readyToMerge = ownPulls.filter { $0.node.readyToMerge }.count
                self.updateStatusCounter(self.reviewURLs.count, actions: actions, readyToMergeCount: readyToMerge)
            } else {
                self.updateStatusCounter((results[Defaults[.counterSelection]] ?? []).count)
            }
            // Keep the footer and its Refresh view alive throughout menu tracking.
            // Insert the new rows before removing old ones so the menu never empties.
            let oldRows = Array(self.menu.items.prefix { $0.tag != self.refreshItemTag })
            for (index, item) in updatedMenu.items.enumerated() {
                updatedMenu.removeItem(item)
                self.menu.insertItem(item, at: index)
            }
            for item in oldRows { self.menu.removeItem(item) }
            self.menu.update()
        }
    }

    func addMenuItems(pull: Edge, to menu: NSMenu) {
        let issueItem = createMenuItem(pull: pull)
        menu.addItem(issueItem)

        // Option alternate: same row as the pull request, with the first line replaced by "Copy Link #123"
        let copyTitle = NSMutableAttributedString(attributedString: issueItem.attributedTitle ?? NSAttributedString(string: issueItem.title))
        let firstLineEnd = (copyTitle.string as NSString).range(of: "\n").location
        let firstLine = NSMutableAttributedString(string: "")
            .appendString(string: "Copy Link", color: NSColor(.primary))
            .appendString(string: " #" + String(pull.node.number))
            .appendSeparator()
        copyTitle.replaceCharacters(in: NSRange(location: 0, length: firstLineEnd == NSNotFound ? copyTitle.length : firstLineEnd), with: firstLine)

        let copyItem = NSMenuItem(title: "", action: #selector(copyLink), keyEquivalent: "")
        copyItem.attributedTitle = copyTitle
        copyItem.isAlternate = true
        copyItem.keyEquivalentModifierMask = [.option]
        copyItem.representedObject = pull.node.url
        copyItem.toolTip = pull.node.url.absoluteString
        menu.addItem(copyItem)

        setAvatar(pull: pull, for: [issueItem, copyItem])
    }

    func setAvatar(pull: Edge, for items: [NSMenuItem]) {
        guard Defaults[.showAvatar] else { return }

        // Set default image initially
        let defaultImage = NSImage(named: "person")!
        let resizedDefaultImage = resizeImage(image: defaultImage, size: NSSize(width: 36.0, height: 36.0))
        items.forEach { $0.image = resizedDefaultImage }

        // Load avatar asynchronously if available
        if let author = pull.node.author, let imageURL = author.avatarUrl {
            NSImage.loadImageAsync(fromURL: imageURL) { loadedImage in
                guard let loadedImage = loadedImage else { return }

                loadedImage.cacheMode = NSImage.CacheMode.always
                let resizedImage = self.resizeImage(image: loadedImage, size: NSSize(width: 36.0, height: 36.0))
                items.forEach { $0.image = resizedImage }
            }
        }
    }
    
    func createMenuItem(pull: Edge) -> NSMenuItem {
        let issueItem = NSMenuItem(title: "", action: #selector(self.openLink), keyEquivalent: "")
        
        let issueItemTitle = NSMutableAttributedString(string: "")
            .appendString(string: pull.node.isReadByViewer ? "" : "⏺ ", color: .systemBlue)
        
        if pull.node.viewerDidAuthor && pull.node.readyToMerge {
            issueItemTitle.appendIcon(iconName: "check-circle-fill", color: .systemGreen)
        }
        
        issueItemTitle
            .appendString(string: pull.node.title.trunc(length: 50), color: NSColor(.primary))
            .appendString(string: " #" +  String(pull.node.number))
            .appendSeparator()
        
        issueItemTitle.appendNewLine()
        
        issueItemTitle
            .appendIcon(iconName: "repo")
            .appendString(string: pull.node.repository.name)
            .appendSeparator()
            .appendIcon(iconName: "person")
            .appendString(string: pull.node.author?.login ?? User.ghost.login)
            .appendSeparator()
            .appendString(string: pull.node.createdAt.creationAgeLabel())
        
        let approvalCount = pull.node.approvalCount
        let approvalColor: NSColor = approvalCount >= 2 ? .systemGreen : .secondaryLabelColor
        issueItemTitle.appendNewLine().appendIcon(iconName: "check-circle", color: approvalColor)
            .appendString(string: "\(approvalCount)/2 approvals", color: approvalColor)
            .appendSeparator()
        let ciColor: NSColor
        switch pull.node.ciState {
        case .passed: ciColor = .systemGreen
        case .failed: ciColor = .systemRed
        case .pending, .running, .queued: ciColor = .systemOrange
        case .missing, .unknown: ciColor = .secondaryLabelColor
        }
        issueItemTitle.appendString(string: pull.node.ciSummary, color: ciColor)
        var states = reasons(for: pull.node)
        if reviewURLs.contains(pull.node.url) { states.insert("Your review requested", at: 0) }
        if !pull.node.detailsComplete { states.append("Review details incomplete — check GitHub") }
        if states.isEmpty {
            switch pull.node.mergeStateStatus {
            case "BLOCKED":
                let waitingForReviews = pull.node.ciState == .passed
                    && pull.node.reviewDecision == "REVIEW_REQUIRED"
                states.append(waitingForReviews
                    ? "Blocked by GitHub requirements - Waiting for reviews"
                    : "Blocked by GitHub requirements")
            case "BEHIND": states.append("Branch needs updating")
            case "UNKNOWN": states.append("Mergeability pending")
            default: states.append("Waiting")
            }
        }
        for start in stride(from: 0, to: states.count, by: 2) {
            let end = min(start + 2, states.count)
            issueItemTitle.appendNewLine()
            for index in start..<end {
                if index > start { issueItemTitle.appendString(string: " · ") }
                let isReady = pull.node.viewerDidAuthor && states[index] == "Ready to merge"
                issueItemTitle.appendString(string: states[index], color: isReady ? .systemGreen : .labelColor)
            }
        }

        if !pull.node.labels.nodes.isEmpty && Defaults[.showLabels] {
            issueItemTitle
                .appendNewLine()
                .appendIcon(iconName: "tag", color: NSColor(.secondary))
            for label in pull.node.labels.nodes {
                issueItemTitle
                    .appendString(string: label.name, color: hexColor(hex: label.color), fontSize: NSFont.smallSystemFontSize)
                    .appendSeparator()
            }
        }
        
        if Defaults[.showCIDiagnostics] {
            for line in pull.node.ciDiagnosticLines(checkLimit: 2) {
                issueItemTitle.appendNewLine().appendString(string: line, color: .secondaryLabelColor, fontSize: 11)
            }
        }
        // Keep the PR itself clickable. CI details are available in GitHub.
        issueItem.attributedTitle = issueItemTitle
        if Defaults[.showCIDiagnostics] {
            issueItem.toolTip = pull.node.title + "\n" + pull.node.ciDiagnosticLines().joined(separator: "\n")
        } else if pull.node.title.count > 50 {
            issueItem.toolTip = pull.node.title
        }
        issueItem.representedObject = pull.node.url
        
        return issueItem
    }
    
    func addMenuFooterItems() {
        let refreshItem = NSMenuItem(title: "Refresh", action: #selector(self.refreshMenu), keyEquivalent: "")
        refreshItem.target = self
        refreshItem.tag = refreshItemTag
        // A button in a custom menu view receives clicks without ending tracking.
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 28))
        let button = NSButton(title: loadingIndicator == nil ? "Refresh" : "Refreshing…",
                              target: self, action: #selector(self.refreshMenu))
        button.frame = NSRect(x: 14, y: 2, width: 172, height: 24)
        button.autoresizingMask = [.width]
        button.isBordered = false
        button.alignment = .left
        button.font = NSFont.menuFont(ofSize: 0)
        button.isEnabled = loadingIndicator == nil
        container.addSubview(button)
        refreshItem.view = container
        refreshButton = button
        self.menu.addItem(refreshItem)
        self.menu.addItem(.separator())
        self.menu.addItem(withTitle: "Preferences...", action: #selector(self.openPrefecencesWindow), keyEquivalent: "")
        // Remove for app store release
//        self.menu.addItem(withTitle: "Check for updates...", action: #selector(self.checkForUpdates), keyEquivalent: "")
        self.menu.addItem(withTitle: "About PullBar", action: #selector(self.openAboutWindow), keyEquivalent: "")
        self.menu.addItem(withTitle: "Quit", action: #selector(self.quit), keyEquivalent: "")
    }
    
    @objc
    func openPrefecencesWindow(_: NSStatusBarButton?) {
        NSLog("Open preferences window")
        let contentView = PreferencesView()
        if preferencesWindow != nil {
            preferencesWindow.close()
        }
        preferencesWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 0, height: 0),
            styleMask: [.closable, .titled],
            backing: .buffered,
            defer: false
        )
        
        preferencesWindow.title = "Preferences"
        preferencesWindow.contentView = NSHostingView(rootView: contentView)
        preferencesWindow.makeKeyAndOrderFront(nil)
        preferencesWindow.styleMask.remove(.resizable)
        
        // allow the preference window can be focused automatically when opened
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        let controller = NSWindowController(window: preferencesWindow)
        controller.showWindow(self)
        
        preferencesWindow.center()
        preferencesWindow.orderFrontRegardless()
    }
    
    @objc
    func openAboutWindow(_: NSStatusBarButton?) {
        NSLog("Open about window")
        let contentView = AboutView()
        if aboutWindow != nil {
            aboutWindow.close()
        }
        aboutWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 500),
            styleMask: [.closable, .titled],
            backing: .buffered,
            defer: false
        )
        
        aboutWindow.title = "About"
        aboutWindow.contentView = NSHostingView(rootView: contentView)
        aboutWindow.makeKeyAndOrderFront(nil)
        aboutWindow.styleMask.remove(.resizable)
        
        // allow the preference window can be focused automatically when opened
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        let controller = NSWindowController(window: aboutWindow)
        controller.showWindow(self)
        
        aboutWindow.center()
        aboutWindow.orderFrontRegardless()
    }
    
    @objc
    func windowClosed(notification: NSNotification) {
        let window = notification.object as? NSWindow
        if let windowTitle = window?.title {
            if (windowTitle == "Preferences") {
                timer?.invalidate()
                timer = Timer.scheduledTimer(
                    timeInterval: Double(Defaults[.refreshRate] * 60),
                    target: self,
                    selector: #selector(refreshMenu),
                    userInfo: nil,
                    repeats: true
                )
                timer?.fire()
            }
        }
    }
    
    @objc
    func quit() {
        NSLog("User click Quit")
        NSApplication.shared.terminate(self)
    }
    
    @objc
    func checkForUpdates(_: NSStatusBarButton?) {
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        ghClient.getLatestRelease { latestRelease in
            if let latestRelease = latestRelease {
                let versionComparison = currentVersion.compare(latestRelease.name.replacingOccurrences(of: "v", with: ""), options: .numeric)
                if versionComparison == .orderedAscending {
                    self.downloadNewVersionDialog(link: latestRelease.assets[0].browserDownloadUrl)
                } else {
                    self.dialogWithText(text: "You have the latest version installed!")
                }
            }
        }
    }
    
    func dialogWithText(text: String) -> Void {
        let alert = NSAlert()
        alert.messageText = text
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    func downloadNewVersionDialog(link: String) -> Void {
        let alert = NSAlert()
        alert.messageText = "New version is available!"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Download")
        alert.addButton(withTitle: "Cancel")
        let pressedButton = alert.runModal()
        if (pressedButton == .alertFirstButtonReturn) {
            NSWorkspace.shared.open(URL(string: link)!)
        }
    }
    
    /// Resizes an NSImage to the specified size
    func resizeImage(image: NSImage, size: NSSize) -> NSImage {
        if image.size.height == size.height && image.size.width == size.width {
            return image
        }
        
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size),
                  from: NSRect(origin: .zero, size: image.size),
                  operation: .sourceOver,
                  fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
}

/// Let clicks on the spinner continue to open the status item's menu.
private final class StatusLoadingIndicator: NSProgressIndicator {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
