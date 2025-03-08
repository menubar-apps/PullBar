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
    
}

extension AppDelegate {
    @objc
    func refreshMenu() {
        NSLog("Refreshing menu")
        self.menu.removeAllItems()

        if (Defaults[.githubUsername] == "" || githubToken == "") {
            addMenuFooterItems()
            return
        }


        var assignedPulls: [Edge]? = []
        var createdPulls: [Edge]? = []
        var reviewRequestedPulls: [Edge]? = []


        let group = DispatchGroup()
        
        if Defaults[.showAssigned] {
            group.enter()
            ghClient.getAssignedPulls() { pulls in
                assignedPulls?.append(contentsOf: pulls)
                group.leave()
            }
        }

        if Defaults[.showCreated] {
            group.enter()
            ghClient.getCreatedPulls() { pulls in
                createdPulls?.append(contentsOf: pulls)
                group.leave()
            }
        }

        if Defaults[.showRequested] {
            group.enter()
            ghClient.getReviewRequestedPulls() { pulls in
                reviewRequestedPulls?.append(contentsOf: pulls)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            
            if let assignedPulls = assignedPulls, let createdPulls = createdPulls, let reviewRequestedPulls = reviewRequestedPulls {
                self.statusBarItem.button?.title = ""

                if Defaults[.showAssigned] && !assignedPulls.isEmpty {
                    if Defaults[.counterType] == .assigned {
                        self.statusBarItem.button?.title = String(assignedPulls.count)
                    }

                    self.menu.addItem(NSMenuItem(title: "Assigned (\(assignedPulls.count))", action: nil, keyEquivalent: ""))
                    for pull in assignedPulls {
                        self.menu.addItem(self.createMenuItem(pull: pull))
                    }
                    self.menu.addItem(.separator())
                }
                
                if Defaults[.showCreated] && !createdPulls.isEmpty {
                    if Defaults[.counterType] == .created {
                        self.statusBarItem.button?.title = String(createdPulls.count)
                    }

                    self.menu.addItem(NSMenuItem(title: "Created (\(createdPulls.count))", action: nil, keyEquivalent: ""))
                    for pull in createdPulls {
                        self.menu.addItem(self.createMenuItem(pull: pull))
                    }
                    self.menu.addItem(.separator())
                }

                if Defaults[.showRequested] && !reviewRequestedPulls.isEmpty {
                    if Defaults[.counterType] == .reviewRequested {
                        self.statusBarItem.button?.title = String(reviewRequestedPulls.count)
                    }

                    self.menu.addItem(NSMenuItem(title: "Review Requested (\(reviewRequestedPulls.count))", action: nil, keyEquivalent: ""))
                    for pull in reviewRequestedPulls {
                        self.menu.addItem(self.createMenuItem(pull: pull))
                    }
                    self.menu.addItem(.separator())
                }
                
                
                self.addMenuFooterItems()
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
            .appendString(string: pull.node.author.login)
        
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
        
        let approvedByMe = pull.node.reviews.edges.contains{ $0.node.author.login == Defaults[.githubUsername] }
        issueItemTitle
            .appendIcon(iconName: "check-circle", color: approvedByMe ? NSColor(named: "green")! : NSColor.secondaryLabelColor)
            .appendString(string: " " + String(pull.node.reviews.totalCount))
            .appendSeparator()
            .appendString(string: "+" + String(pull.node.additions ?? 0), color: NSColor(named: "green")!)
            .appendString(string: " -" + String(pull.node.deletions ?? 0), color: NSColor(named: "red")!)
            .appendSeparator()
            .appendIcon(iconName: "calendar")
            .appendString(string: pull.node.createdAt.getElapsedInterval())
        
        if Defaults[.showAvatar] {
            var image = NSImage()
            if let imageURL = pull.node.author.avatarUrl {
                image = NSImage.imageFromUrl(fromURL: imageURL) ?? NSImage(named: "person")!
            } else {
                image = NSImage(named: "person")!
            }
            image.cacheMode = NSImage.CacheMode.always
            if ((image.size.height != 36) || (image.size.width != 36)) {
                image.size = NSSize(width: 36.0, height: 36.0)
            }
            issueItem.image = image
        }
        
        
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
}
