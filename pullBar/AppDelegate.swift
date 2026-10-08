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

    @FromKeychain(.bitbucketToken) var bitbucketToken
    @FromKeychain(.bitbucketUsername) var bitbucketUsername
    @FromKeychain(.githubToken) var legacyGithubToken

    let bbClient = BitbucketClient()
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
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    @objc
    func openLink(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.open(url)
    }

    /// Categories used to store a GitHub search query; on first launch after the
    /// Bitbucket migration reset them to the role-based defaults so stored
    /// GitHub filters don't leak into the new model.
    func migrateCategoriesIfNeeded() {
        // The legacy GitHub token is no longer usable; remove it rather than
        // leaving a stale secret in the Keychain.
        if !legacyGithubToken.isEmpty {
            legacyGithubToken = ""
        }

        if Defaults[.categoriesSchemaVersion] < 4 {
            Defaults[.categoriesSchemaVersion] = 4
            // Existing categories decode into the new role model (a missing
            // `role` falls back to `.all`), so preserve them. Only a fresh
            // install with no stored categories gets the default seed.
            if Defaults[.categories].isEmpty {
                Defaults[.categories] = SearchCategory.defaultCategories
            }
            // Preserve a counter selection that still references a valid
            // category; only fall back to the default when the stored id no
            // longer exists.
            let counter = Defaults[.counterSelection]
            let validIds = Set(Defaults[.categories].map { $0.id })
            if counter != SearchCategory.counterNone && !validIds.contains(counter) {
                Defaults[.counterSelection] = SearchCategory.counterNone
            }
        }
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

        if (bitbucketToken.isEmpty || bitbucketUsername.isEmpty) {
            self.menu.removeAllItems()
            addMenuFooterItems()
            return
        }

        let categories = Defaults[.categories]
        let counter = Defaults[.counterSelection]

        var pullsByCategory: [String: [BitbucketPull]] = [:]

        let group = DispatchGroup()

        for category in categories {
            group.enter()
            bbClient.getPulls(role: category.role) { pulls in
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

    func addMenuItems(pull: BitbucketPull, to menu: NSMenu) {
        let issueItem = createMenuItem(pull: pull)
        menu.addItem(issueItem)

        // Option alternate: same row as the pull request, with the first line replaced by "Copy Link #123"
        let copyTitle = NSMutableAttributedString(attributedString: issueItem.attributedTitle ?? NSAttributedString(string: issueItem.title))
        let firstLineEnd = (copyTitle.string as NSString).range(of: "\n").location
        let firstLine = NSMutableAttributedString(string: "")
            .appendString(string: "Copy Link", color: NSColor(.primary))
            .appendString(string: " #" + String(pull.id))
            .appendSeparator()
        copyTitle.replaceCharacters(in: NSRange(location: 0, length: firstLineEnd == NSNotFound ? copyTitle.length : firstLineEnd), with: firstLine)

        let copyItem = NSMenuItem(title: "", action: #selector(copyLink), keyEquivalent: "")
        copyItem.attributedTitle = copyTitle
        copyItem.isAlternate = true
        copyItem.keyEquivalentModifierMask = [.option]
        if let url = BitbucketClient.webUrl(for: pull, baseUrl: Defaults[.bitbucketBaseUrl]) {
            copyItem.representedObject = url
            copyItem.toolTip = url.absoluteString
        }
        menu.addItem(copyItem)

        setAvatar(pull: pull, for: [issueItem, copyItem])
    }

    func setAvatar(pull: BitbucketPull, for items: [NSMenuItem]) {
        guard Defaults[.showAvatar] else { return }

        // Set default image initially
        let defaultImage = NSImage(named: "person")!
        let resizedDefaultImage = resizeImage(image: defaultImage, size: NSSize(width: 36.0, height: 36.0))
        items.forEach { $0.image = resizedDefaultImage }

        // Load avatar asynchronously if available
        if let href = pull.author.user.links?.avatar?.first?.href,
           let imageURL = validatedAvatarUrl(href) {
            NSImage.loadImageAsync(fromURL: imageURL) { loadedImage in
                guard let loadedImage = loadedImage else { return }

                loadedImage.cacheMode = NSImage.CacheMode.always
                let resizedImage = self.resizeImage(image: loadedImage, size: NSSize(width: 36.0, height: 36.0))
                items.forEach { $0.image = resizedImage }
            }
        }
    }

    /// Only loads avatar images served over `https` from the configured
    /// Bitbucket host, so a server- or author-influenced href cannot direct the
    /// app to an arbitrary origin or a non-TLS scheme.
    private func validatedAvatarUrl(_ href: String) -> URL? {
        guard let url = URL(string: href),
              url.scheme?.lowercased() == "https",
              let host = url.host, !host.isEmpty,
              let baseHost = URL(string: Defaults[.bitbucketBaseUrl])?.host,
              host.caseInsensitiveCompare(baseHost) == .orderedSame else {
            return nil
        }
        return url
    }

    func createMenuItem(pull: BitbucketPull) -> NSMenuItem {
        let issueItem = NSMenuItem(title: "", action: #selector(self.openLink), keyEquivalent: "")

        var issueItemTitle = NSMutableAttributedString(string: "")

        if (pull.state == "OPEN") {
            issueItemTitle.appendString(string: "⏺ ", color: .systemBlue)
        }

        if (pull.state == "MERGED") {
            issueItemTitle.appendString(string: "MERGED ", color: .gray)
        }

        issueItemTitle
            .appendString(string: pull.title.trunc(length: 50), color: NSColor(.primary))
            .appendString(string: " #" + String(pull.id))
            .appendSeparator()

        issueItemTitle.appendNewLine()

        issueItemTitle
            .appendIcon(iconName: "repo")
            .appendString(string: pull.repositoryName)
            .appendSeparator()
            .appendIcon(iconName: "person")
            .appendString(string: pull.authorName)

        issueItemTitle.appendNewLine()

        let approved = pull.approvedViewerCount
        issueItemTitle
            .appendIcon(iconName: "check-circle", color: approved > 0 ? NSColor(named: "green")! : NSColor.secondaryLabelColor)
            .appendString(string: " " + String(approved))
            .appendSeparator()
            .appendIcon(iconName: "calendar")
            .appendString(string: pull.created.getElapsedInterval())

        issueItem.attributedTitle = issueItemTitle
        if pull.title.count > 50 {
            issueItem.toolTip = pull.title
        }
        if let url = BitbucketClient.webUrl(for: pull, baseUrl: Defaults[.bitbucketBaseUrl]) {
            issueItem.representedObject = url
        }

        return issueItem
    }

    func addMenuFooterItems() {
        self.menu.addItem(withTitle: "Refresh", action: #selector(self.refreshMenu), keyEquivalent: "")
        self.menu.addItem(.separator())
        self.menu.addItem(withTitle: "Preferences...", action: #selector(self.openPrefecencesWindow), keyEquivalent: "")
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