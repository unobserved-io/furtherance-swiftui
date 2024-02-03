//
//  FurtheranceShortcuts.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/2/24.
//

import AppIntents

struct FurtheranceShortcuts: AppShortcutsProvider {
    /// Define shortcuts available in Furtherance so they are available through Siri
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartFurtheranceTimerIntent(),
            phrases: [
                "Start a \(.applicationName) timer",
                "Start a \(.applicationName) task",
                "Start a new \(.applicationName) timer",
                "Start a new \(.applicationName) task",
                "Begin a \(.applicationName) timer",
                "Begin a \(.applicationName) task",
                "Start a timer with \(.applicationName)",
                "Start a task with \(.applicationName)",
                "Start a timer in \(.applicationName)",
                "Start a task in \(.applicationName)",
            ],
            shortTitle: "Start Furtherance Timer",
            systemImageName: "timer"
        )
        AppShortcut(
            intent: StopFurtheranceTimerIntent(),
            phrases: [
                "Stop the \(.applicationName) timer",
                "Stop the \(.applicationName) task",
                "Stop my \(.applicationName) timer",
                "Stop my \(.applicationName) task",
                "Stop \(.applicationName) timer",
                "Stop \(.applicationName) task",
                "End \(.applicationName) timer",
                "End \(.applicationName) task",
                "End the \(.applicationName) time",
                "End the \(.applicationName) task",
                "End my \(.applicationName) timer",
                "End my \(.applicationName) task",
                "Stop the running \(.applicationName) timer",
                "Stop the task I have in \(.applicationName)"
            ],
            shortTitle: "Stop Furtherance Timer",
            systemImageName: "stop.fill"
        )
    }
}
