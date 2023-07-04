//
//  AppDelegate.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 6/23/23.
//
#if os(macOS)
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
#endif
