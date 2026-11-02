//
//  Notifications.swift
//  pullBar
//
//  Created by Casey Jones on 2021-12-28.
//

import Foundation
import UserNotifications

func sendNotification(title: String = "PullBar", body: String = "", url: URL? = nil) {
  let content = UNMutableNotificationContent()
  content.title = title

  if body.count > 0 {
    content.body = body
  }

  if let url = url {
    content.userInfo = ["url": url.absoluteString]
  }

  let request = UNNotificationRequest(
    identifier: url?.absoluteString ?? UUID().uuidString,
    content: content, trigger: nil)

  let notificationCenter = UNUserNotificationCenter.current()
  notificationCenter.requestAuthorization(options: [.alert, .sound]) { _, _ in }
  notificationCenter.add(request)
}
