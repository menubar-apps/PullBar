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
    
    @Default(.showAssigned) var showAssigned
    @Default(.showCreated) var showCreated
    @Default(.showRequested) var showRequested
    
    @Default(.showAvatar) var showAvatar
    @Default(.showChecks) var showChecks
    @Default(.showLabels) var showLabels
    
    @Default(.refreshRate) var refreshRate
    
    @Default(.githubUsername) var githubUsername
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
            timeInterval: Double(refreshRate * 60),
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
        self.statusBarItem.button?.title = ""
        
        if (githubUsername == "" || githubToken == "") {
            addMenuFooterItems()
            return
        }
        
        
        var assignedPulls: [Edge]? = []
        var createdPulls: [Edge]? = []
        var reviewRequestedPulls: [Edge]? = []
        
        
        let group = DispatchGroup()
        
        if showAssigned {
            group.enter()
            ghClient.getAssignedPulls() { pulls in
                assignedPulls?.append(contentsOf: pulls)
                group.leave()
            }
        }
            
        if showCreated {
            group.enter()
            ghClient.getCreatedPulls() { pulls in
                createdPulls?.append(contentsOf: pulls)
                group.leave()
            }
        }

        if showRequested {
            group.enter()
            ghClient.getReviewRequestedPulls() { pulls in
                reviewRequestedPulls?.append(contentsOf: pulls)
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            
            let isOneSelected = (self.showAssigned.intValue + self.showCreated.intValue + self.showRequested.intValue) == 1

            
            if let assignedPulls = assignedPulls, let createdPulls = createdPulls, let reviewRequestedPulls = reviewRequestedPulls {
                
                if self.showAssigned && !assignedPulls.isEmpty {
                    self.menu.addItem(NSMenuItem(title: "Assigned (\(assignedPulls.count))", action: nil, keyEquivalent: ""))
                    for pull in assignedPulls {
                        self.menu.addItem(self.createMenuItem(pull: pull))
                    }
                    self.menu.addItem(.separator())
                    if isOneSelected {
                        self.statusBarItem.button?.title = String(assignedPulls.count)
                    }
                }
                
                if self.showCreated && !createdPulls.isEmpty {
                    self.menu.addItem(NSMenuItem(title: "Created (\(createdPulls.count))", action: nil, keyEquivalent: ""))
                    for pull in createdPulls {
                        self.menu.addItem(self.createMenuItem(pull: pull))
                    }
                    self.menu.addItem(.separator())
                    if isOneSelected {
                        self.statusBarItem.button?.title = String(createdPulls.count)
                    }

                }

                if self.showRequested && !reviewRequestedPulls.isEmpty {
                    self.menu.addItem(NSMenuItem(title: "Review Requested (\(reviewRequestedPulls.count))", action: nil, keyEquivalent: ""))
                    for pull in reviewRequestedPulls {
                        self.menu.addItem(self.createMenuItem(pull: pull))
                    }
                    self.menu.addItem(.separator())
                    if isOneSelected {
                        self.statusBarItem.button?.title = String(reviewRequestedPulls.count)
                    }

                }
                
                
                self.addMenuFooterItems()
            }
        }
    }
    
    func createMenuItem(pull: Edge) -> NSMenuItem {
        let issueItem = NSMenuItem(title: "", action: #selector(self.openLink), keyEquivalent: "")
        
        let issueItemTitle = NSMutableAttributedString(string: pull.node.title.trunc(length: 50))
            .appendString(string: " #" +  String(pull.node.number))
            .appendSeparator()
            .appendIcon(iconName: pull.node.isDraft ? "git-draft-pull-request" : "git-pull-request", color: pull.node.isDraft ? NSColor.secondaryLabelColor : NSColor(named: "green")!)
            .appendString(string: pull.node.isDraft ? "Draft" : "Open", color: pull.node.isDraft ? NSColor.secondaryLabelColor : NSColor(named: "green")!)
        
        issueItemTitle.appendNewLine()

        issueItemTitle
            .appendIcon(iconName: "repo")
            .appendString(string: pull.node.repository.name)
            .appendSeparator()
            .appendIcon(iconName: "person")
            .appendString(string: pull.node.author.login)
                
        if !pull.node.labels.nodes.isEmpty && self.showLabels {
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
        
        let approvedByMe = pull.node.reviews.edges.contains{ $0.node.author.login == githubUsername }
        issueItemTitle
            .appendIcon(iconName: "check-circle", color: approvedByMe ? NSColor(named: "green")! : NSColor.secondaryLabelColor)
            .appendString(string: " " + String(pull.node.reviews.totalCount))
            .appendSeparator()
            .appendString(string: "+" + String(pull.node.additions ?? 0), color: NSColor(named: "green")!)
            .appendString(string: " -" + String(pull.node.deletions ?? 0), color: NSColor(named: "red")!)
            .appendSeparator()
            .appendIcon(iconName: "calendar")
            .appendString(string: pull.node.createdAt.getElapsedInterval())

        if showAvatar {
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
            if commits.nodes[0].commit.checkSuites.nodes.count > 0 {
                issueItem.submenu = NSMenu()
                issueItemTitle
                    .appendSeparator()
                    .appendIcon(iconName: "checklist", color: NSColor.secondaryLabelColor)
            }
            for checkSuite in commits.nodes[0].commit.checkSuites.nodes {
                
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
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
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
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 340),
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
                    timeInterval: Double(refreshRate * 60),
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
}
