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

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @Default(.showAssigned) var showAssigned
    @Default(.showCreated) var showCreated
    @Default(.showRequested) var showRequested
    
    @Default(.showAvatar) var showAvatar
    
    @Default(.refreshRate) var refreshRate
    
    let ghClient = GitHubClient()
    var statusBarItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let menu: NSMenu = NSMenu()
    var preferencesWindow: NSWindow!
    
    var timer: Timer? = nil
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NotificationCenter.default.addObserver(self, selector: #selector(AppDelegate.windowClosed), name: NSWindow.willCloseNotification, object: nil)
        
        guard let statusButton = statusBarItem.button else { return }
        statusButton.title = "hello"
        let icon = NSImage(named: "git-pull-request")
        let size = NSSize(width: 16, height: 16)
        icon?.isTemplate = true
        icon?.size = size
        statusButton.image = icon
        
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
            
            
            if let assignedPulls = assignedPulls, let createdPulls = createdPulls, let reviewRequestedPulls = reviewRequestedPulls {

                if self.showAssigned {
                    self.menu.addItem(NSMenuItem(title: "Assigned", action: nil, keyEquivalent: ""))
                    for pull in assignedPulls {
                        self.menu.addItem(self.createMenuItem(pull: pull))
                    }
                    self.menu.addItem(.separator())
                }
                
                if self.showCreated {
                    self.menu.addItem(NSMenuItem(title: "Created", action: nil, keyEquivalent: ""))
                    for pull in createdPulls {
                        self.menu.addItem(self.createMenuItem(pull: pull))
                    }
                    self.menu.addItem(.separator())
                }

                if self.showRequested {
                    self.menu.addItem(NSMenuItem(title: "Review Requested", action: nil, keyEquivalent: ""))
                    for pull in reviewRequestedPulls {
                        self.menu.addItem(self.createMenuItem(pull: pull))
                    }
                    self.menu.addItem(.separator())
                }
                
                self.menu.addItem(withTitle: "Refresh", action: #selector(self.refreshMenu), keyEquivalent: "R")
                self.menu.addItem(.separator())
                self.menu.addItem(withTitle: "Preferences...", action: #selector(self.openPrefecencesWindow), keyEquivalent: ",")
                self.menu.addItem(withTitle: "Quit", action: #selector(self.quit), keyEquivalent: "q")
            }
            
        }
    }
    
    func createMenuItem(pull: Edge) -> NSMenuItem {
        let issueItem = NSMenuItem(title: "", action: #selector(self.openLink), keyEquivalent: "")
        let issueItemTitle = NSMutableAttributedString(string: pull.node.title)
            .appendString(string: " #" +  String(pull.node.number), color: "#888888")
        
        issueItemTitle.appendNewLine()

        issueItemTitle
            .appendIcon(iconName: "repo")
            .appendString(string: pull.node.repository.name, color: "#888888")
            .appendSeparator()
            .appendIcon(iconName: "person")
            .appendString(string: pull.node.author.login, color: "#888888")
        
        issueItemTitle.appendNewLine()
        
        issueItemTitle
            .appendIcon(iconName: "check-circle-gray")
            .appendString(string: " " + String(pull.node.reviews.totalCount), color: "#888888")
            .appendSeparator()
            .appendString(string: "+" + String(pull.node.additions ?? 0), color: "#A3BE8C")
            .appendString(string: " -" + String(pull.node.deletions ?? 0), color: "#BF616A")
            .appendSeparator()
            .appendIcon(iconName: "calendar")
            .appendString(string: pull.node.createdAt.getElapsedInterval(), color: "#888888")

        if showAvatar {
            let imageURL = pull.node.author.avatarUrl
            var image = NSImage.imageFromUrl(fromURL: imageURL) ?? NSImage(named: "person")!
            image.cacheMode = NSImage.CacheMode.always
            if ((image.size.height != 36) || (image.size.width != 36)) {
                image = image.resized(to: NSSize(width: 36.0, height: 36.0))!
            }
            issueItem.image = image
        }
        
        issueItem.attributedTitle = issueItemTitle
        issueItem.representedObject = pull.node.url
        
        return issueItem
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
        // allow the preference window can be focused automatically when opened
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        let controller = NSWindowController(window: preferencesWindow)
        controller.showWindow(self)
        
        preferencesWindow.center()
        preferencesWindow.orderFrontRegardless()
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
    func quit(_: NSStatusBarButton) {
        NSLog("User click Quit")
        NSApplication.shared.terminate(self)
    }
    

}
