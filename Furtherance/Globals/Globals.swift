//
//  Globals.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 3/12/23.
//

import Foundation

func formatTimeShort(_ totalSeconds: Int) -> String {
    /// Format input seconds into a time format that does not include hours if there isn't any, and doesn't pad the hours
    let hours = totalSeconds / 3600
    let hoursString = String(hours)
    let minutes = (totalSeconds % 3600) / 60
    let minutesString = (minutes < 10) ? "0\(minutes)" : "\(minutes)"
    let seconds = totalSeconds % 60
    let secondsString = (seconds < 10) ? "0\(seconds)" : "\(seconds)"
    if hours > 0 {
        return hoursString + ":" + minutesString + ":" + secondsString
    } else {
        return minutesString + ":" + secondsString
    }
}