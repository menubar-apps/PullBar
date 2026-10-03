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
        NSWorkspace.shared.open(sender.representedObject as! URL)
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
    @objc
    func refreshMenu() {
        NSLog("Refreshing menu")

        if (githubToken == "") {
            self.menu.removeAllItems()
            addMenuFooterItems()
            return
        }


        let categories = Defaults[.categories].filter {
            !$0.filter.trimmingCharacters(in: .whitespaces).isEmpty
        }
        let counter = Defaults[.counterSelection]

        var pullsByCategory: [String: [Edge]] = [:]

        let group = DispatchGroup()

        for category in categories {
            group.enter()
            ghClient.getPulls(filter: category.filter) { pulls in
                pullsByCategory[category.id, default: []].append(contentsOf: pulls)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            // An empty NSMenu will not open, so hold the previous items until
            // the new ones are ready to replace them.
            self.menu.removeAllItems()
            self.statusBarItem.button?.title = ""

            // Only categories that actually have pull requests are rendered.
            let visibleCategories = categories.filter { !(pullsByCategory[$0.id] ?? []).isEmpty }

            for (index, category) in visibleCategories.enumerated() {
                let pulls = pullsByCategory[category.id] ?? []
                let headerTitle = "\(category.displayName) (\(pulls.count))"

                if category.asSubmenu {
                    let parent = NSMenuItem(title: headerTitle, action: nil, keyEquivalent: "")
                    let submenu = NSMenu()
                    for pull in pulls {
                        self.addMenuItems(pull: pull, to: submenu)
                    }
                    parent.submenu = submenu
                    self.menu.addItem(parent)
                } else {
                    self.menu.addItem(NSMenuItem(title: headerTitle, action: nil, keyEquivalent: ""))
                    for pull in pulls {
                        self.addMenuItems(pull: pull, to: self.menu)
                    }
                }

                // Keep adjacent submenu categories grouped: no separator between
                // two consecutive submenu items.
                let next = index + 1 < visibleCategories.count ? visibleCategories[index + 1] : nil
                let groupedWithNext = category.asSubmenu && (next?.asSubmenu ?? false)
                if !groupedWithNext {
                    self.menu.addItem(.separator())
                }
            }

            let counterCount = (pullsByCategory[counter] ?? []).count
            if counterCount > 0 {
                self.statusBarItem.button?.title = String(counterCount)
            }

            self.addMenuFooterItems()
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
        
        if (pull.node.isDraft) {
            issueItemTitle
                .appendIcon(iconName: "git-draft-pull-request", color: NSColor.secondaryLabelColor)
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
        
        issueItemTitle.appendNewLine()
        
        let approvedByMe = pull.node.reviews.edges.contains{ $0.node.viewerDidAuthor }
        issueItemTitle
            .appendIcon(iconName: "check-circle", color: approvedByMe ? NSColor(named: "green")! : NSColor.secondaryLabelColor)
            .appendString(string: " " + String(pull.node.reviews.totalCount))
            .appendSeparator()
            .appendString(string: "+" + String(pull.node.additions ?? 0), color: NSColor(named: "green")!)
            .appendString(string: " -" + String(pull.node.deletions ?? 0), color: NSColor(named: "red")!)
            .appendSeparator()
            .appendIcon(iconName: "calendar")
            .appendString(string: pull.node.createdAt.getElapsedInterval())
        
        if let commits = pull.node.commits {
            
            if let checkSuites = commits.nodes[0].commit.checkSuites {
                
                if checkSuites.nodes.count > 0 {
                    issueItem.submenu = NSMenu()
                    issueItemTitle
                        .appendSeparator()
                        .appendIcon(iconName: "checklist", color: NSColor.secondaryLabelColor)
                }
                for checkSuite in checkSuites.nodes {
                    
                    if checkSuite.checkRuns.nodes.count > 0 {
                        issueItem.submenu?.addItem(withTitle: checkSuite.app?.name ?? "empty", action: nil, keyEquivalent: "")
                    }
                    for check in checkSuite.checkRuns.nodes {
                        
                        let buildItem = NSMenuItem(title: check.name, action: #selector(self.openLink), keyEquivalent: "")
                        buildItem.representedObject = check.detailsUrl
                        buildItem.toolTip = check.conclusion
                        if check.conclusion  == "SUCCESS" {
                            buildItem.image = NSImage(named: "check-circle-fill")!.tint(color: NSColor(named: "green")!)
                            issueItemTitle.appendIcon(iconName: "dot-fill", color: NSColor(named: "green")!)
                        } else if check.conclusion  == "FAILURE" {
                            buildItem.image = NSImage(named: "x-circle-fill")!.tint(color: NSColor(named: "red")!)
                            issueItemTitle.appendIcon(iconName: "dot-fill", color: NSColor(named: "red")!)
                        } else if check.conclusion  == "ACTION_REQUIRED" {
                            buildItem.image = NSImage(named: "issue-draft")!.tint(color: NSColor(named: "yellow")!)
                            issueItemTitle.appendIcon(iconName: "dot-fill", color: NSColor(named: "yellow")!)
                        } else {
                            buildItem.image = NSImage(named: "question")!.tint(color: NSColor.gray)
                            issueItemTitle.appendIcon(iconName: "dot-fill", color: NSColor.gray)
                        }
                        
                        issueItem.submenu?.addItem(buildItem)
                    }
                }
            }
            
            else if let statusCheckRollup = commits.nodes[0].commit.statusCheckRollup {
                
                if statusCheckRollup.contexts.nodes.count > 0 {
                    issueItem.submenu = NSMenu()
                    issueItemTitle
                        .appendSeparator()
                        .appendIcon(iconName: "checklist", color: NSColor.secondaryLabelColor)
                }
                
                for check in statusCheckRollup.contexts.nodes {
                    let itemTitle = NSMutableAttributedString()
                    itemTitle.appendString(string: check.name ?? check.context ?? "<empty>", color: NSColor(.primary))
                    itemTitle.appendNewLine()
                        .appendString(string: check.description ?? check.title ?? "<empty>", color: NSColor(.secondary))
                    
                    let buildItem = NSMenuItem(title: "", action: #selector(AppDelegate.openLink), keyEquivalent: "")
                    buildItem.attributedTitle = itemTitle
                    
                    buildItem.representedObject = check.detailsUrl ?? URL.init(string:check.targetUrl ?? "")
                    
                    buildItem.toolTip = check.conclusion ?? check.state ?? ""
                    
                    let status = check.conclusion ?? check.state ?? ""
                    switch status {
                    case "SUCCESS":
                        buildItem.image = NSImage(named: "check-circle-fill")!.tint(color: NSColor(named: "green")!)
                        issueItemTitle.appendIcon(iconName: "dot-fill", color: NSColor(named: "green")!)
                    case "FAILURE":
                        buildItem.image = NSImage(named: "x-circle-fill")!.tint(color: NSColor(named: "red")!)
                        issueItemTitle.appendIcon(iconName: "dot-fill", color: NSColor(named: "red")!)
                    case "PENDING":
                        buildItem.image = NSImage(named: "issue-draft")!.tint(color: NSColor(named: "yellow")!)
                        issueItemTitle.appendIcon(iconName: "dot-fill", color: NSColor(named: "yellow")!)
                    default:
                        buildItem.image = NSImage(named: "question")!.tint(color: NSColor.gray)
                        issueItemTitle.appendIcon(iconName: "dot-fill", color: NSColor.gray)
                        
                    }
                    issueItem.submenu?.addItem(buildItem)
                }
            }
        }
        
        issueItem.attributedTitle = issueItemTitle
        if pull.node.title.count > 50 {
            issueItem.toolTip = pull.node.title
        }
        issueItem.representedObject = pull.node.url
        
        return issueItem
    }
    
    func addMenuFooterItems() {
        self.menu.addItem(withTitle: "Refresh", action: #selector(self.refreshMenu), keyEquivalent: "")
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
