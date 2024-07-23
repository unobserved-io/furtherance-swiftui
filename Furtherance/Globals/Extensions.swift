//
//  Extensions.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 6/8/23.
//

import SwiftUI

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? .now
    }
    
    var startOfWeek: Date {
        Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: self).date ?? .now
    }
    
    var endOfWeek: Date {
        var components = DateComponents()
        components.weekOfYear = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfWeek) ?? .now
    }
    
    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: startOfDay)
        return Calendar.current.date(from: components) ?? .now
    }

    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth) ?? .now
    }
    
    var trimMilliseconds: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
        return calendar.date(from: components) ?? self
    }

}

extension PresentationDetent {
    static let taskBar = Self.fraction(0.4)
    static let groupNameBar = Self.fraction(0.25)
}

extension FurTask {
    /// Return the string representation of the relative date for the supported range (year, month, and day)
    /// The ranges include today, yesterday, the formatted date, and unknown
    @objc
    var startDateRelative: String {
        var result = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy"
        
        if let unwrappedStart = startTime {
            // Order matters here to avoid overlapping
            if Calendar.current.isDateInToday(unwrappedStart) {
                result = "today"
            } else if Calendar.current.isDateInYesterday(unwrappedStart) {
                result = "yesterday"
            } else {
                result = dateFormatter.string(from: unwrappedStart)
            }
        } else {
            result = "unknown"
        }
        return result
    }
}

extension Color {
    static var random: Color {
        let hexElements = "123456789ABCDEF"
        let hexColor = String((0..<6).map{ _ in hexElements.randomElement() ?? "F" })
        return Color(hex: hexColor + "FF") ?? Color.accentColor
    }
}
