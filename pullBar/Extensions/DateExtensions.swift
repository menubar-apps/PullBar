//
//  DateExtensions.swift
//  pullBar
//
//  Created by Pavel Makhov on 2021-11-21.
//

import Foundation

extension Date {
    func creationAgeLabel(now: Date = Date()) -> String {
        let minutes = max(0, Int(now.timeIntervalSince(self) / 60))
        if minutes == 0 { return "Created just now" }
        if minutes < 60 {
            return "Created \(minutes) minute\(minutes == 1 ? "" : "s") ago"
        }
        let hours = minutes / 60
        if hours < 24 {
            return "Created \(hours) hour\(hours == 1 ? "" : "s") ago"
        }
        if hours < 48 {
            let remainingHours = hours - 24
            if remainingHours == 0 { return "Created 1 day ago" }
            return "Created 1 day and \(remainingHours) hour\(remainingHours == 1 ? "" : "s") ago"
        }
        return "Created \(hours / 24) days ago"
    }
    
    func getElapsedInterval() -> String {
        
        let interval = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self, to: Date())
        
        if let year = interval.year, year > 0 {
            return "\(year) year\(year == 1 ? "" : "s") ago"
        } else if let month = interval.month, month > 0 {
            return "\(month) month\(month == 1 ? "" : "s") ago"
        } else if let day = interval.day, day > 0 {
            return "\(day) day\(day == 1 ? "" : "s") ago"
        } else if let hour = interval.hour, hour > 0 {
            return "\(hour) hour\(hour == 1 ? "" : "s") ago"
        } else if let minute = interval.minute, minute > 0 {
            return "\(minute) minute\(minute == 1 ? "" : "s") ago"
        } else if let second = interval.second, second > 0 {
            return "\(second) second\(second == 1 ? "" : "s") ago"
        } else {
            return "a moment ago"
        }
        
    }
}
