//
//  Notifications.swift
//  pullBar
//
//  Created by Casey Jones on 2021-12-28.
//

import Foundation
import UserNotifications

func sendNotification(body: String = "") {
  let content = UNMutableNotificationContent()
  content.title = "PullBar"

  if body.count > 0 {
    content.body = body
  }
  
  // you can alse add a subtitle
//  content.subtitle = "subtitle here... "

  let uuidString = UUID().uuidString
  let request = UNNotificationRequest(
    identifier: uuidString,
    content: content, trigger: nil)

  let notificationCenter = UNUserNotificationCenter.current()
  notificationCenter.requestAuthorization(options: [.alert, .sound]) { _, _ in }
  notificationCenter.add(request)
}
