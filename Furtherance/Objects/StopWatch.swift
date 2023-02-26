//
//  StopWatch.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 2/23/23.
//

import Foundation
import SwiftUI
import UserNotifications

final class StopWatch: ObservableObject {
    static let sharedInstance = StopWatch()
    let persistenceController = PersistenceController.shared
    
    @Published var timeElapsedFormatted = "00:00:00"
    @Published var isRunning = false
    @Published var secondsElapsed = 0
    @Published var showingAlert = false
    
    @AppStorage("idleDetect") private var idleDetect = false
    @AppStorage("idleLimit") private var idleLimit = 6
    @AppStorage("pomodoro") private var pomodoro = false
    @AppStorage("pomodoroTime") private var pomodoroTime = 25
    
    let usbInfoRaw: io_service_t = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOHIDSystem"))
    
    var startTime = Date.now
    var completedSecondsElapsed = 0
    var timer = Timer()
    var idleTimeReached = false
    var idleNotified = false
    var idleStartTime = Date.now
    var howLongIdle = ""
    var timeAtSleep = Date.now
    var idleAtSleep = 0
    
    init() {
        getPomodoroTime()
    }
    
    func getPomodoroTime() {
        /// Format the pomodoro time to use for the stop watch clock
        if !isRunning {
            if pomodoro {
                let pomodoroSecs = pomodoroTime * 60
                let hours = pomodoroSecs / 3600
                let hoursString = (hours < 10) ? "0\(hours)" : "\(hours)"
                let minutes = (pomodoroSecs % 3600) / 60
                let minutesString = (minutes < 10) ? "0\(minutes)" : "\(minutes)"
                let seconds = pomodoroSecs % 60
                let secondsString = (seconds < 10) ? "0\(seconds)" : "\(seconds)"
                timeElapsedFormatted = hoursString + ":" + minutesString + ":" + secondsString
            } else {
                timeElapsedFormatted = "00:00:00"
            }
        }
    }
    
    @objc private func sleepListener(_ aNotification: Notification) {
        /// Check if the computer is going to sleep
        if idleDetect {
            if aNotification.name == NSWorkspace.willSleepNotification {
                print("Going to sleep")
                timeAtSleep = Date.now
                idleAtSleep = getIdleTime()
                idleStartTime = timeAtSleep.addingTimeInterval(Double(-idleAtSleep))
            } else if aNotification.name == NSWorkspace.didWakeNotification {
                print("Woke up")
                let selectedIdle = idleLimit * 60
                let timeAsleep = Calendar.current.dateComponents([.second], from: timeAtSleep, to: Date.now).second ?? 0
                let idleAfterSleep = timeAsleep + idleAtSleep
                if idleAfterSleep > selectedIdle {
                    resumeFromIdle()
                }
            }
        }
    }
    
    func registerLocal(notificationType: String) {
        /// Register notification handler
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge, .provisional]) { granted, error in
            if granted {
                if notificationType == "idle" {
                    self.scheduleLocalIdleNotification()
                } else if notificationType == "pomodoro" {
                    self.scheduleLocalPomodoroNotification()
                }
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    func scheduleLocalIdleNotification() {
        /// Setup notifications for when user comes back from being idle
        let content = UNMutableNotificationContent()
        content.title = "You have been idle for \(howLongIdle)"
        content.body = "Open Furtherance to continue or discard the idle time."
        content.categoryIdentifier = "idle"
        content.sound = UNNotificationSound.default
        content.relevanceScore = 1.0
        content.interruptionLevel = UNNotificationInterruptionLevel.active
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleLocalPomodoroNotification() {
        /// Set up notifications for Pomodoro timer
        let content = UNMutableNotificationContent()
        content.title = "Time's up!"
        content.body = "It's time to take a break."
        content.categoryIdentifier = "pomodoro"
        content.sound = UNNotificationSound.default
        content.relevanceScore = 1.0
        content.interruptionLevel = UNNotificationInterruptionLevel.active
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func start() {
        /// Start the timer
        isRunning = true
        startTime = Date.now
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if self.pomodoro {
                self.secondsElapsed = (self.pomodoroTime * 60) - (Calendar.current.dateComponents([.second], from: self.startTime, to: Date.now).second ?? 0)
            } else {
                self.secondsElapsed = Calendar.current.dateComponents([.second], from: self.startTime, to: Date.now).second ?? 0
            }
            self.formatTime()
            if self.idleDetect {
                self.checkUserIdle()
            }
            if self.secondsElapsed != 0 && self.secondsElapsed % 60 == 0 {
                Autosave().write()
            }
        }
        // Set computer sleep observers
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleepListener(_:)), name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleepListener(_:)), name: NSWorkspace.didWakeNotification, object: nil)
    }

    func stop() {
        /// Stop the timer
        timer.invalidate()
        isRunning = false
        completedSecondsElapsed = secondsElapsed
        secondsElapsed = 0
        timeElapsedFormatted = "00:00:00"
        resetIdle()
        // Destroy sleep observers
        NSWorkspace.shared.notificationCenter.removeObserver(self, name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.removeObserver(self, name: NSWorkspace.didWakeNotification, object: nil)
        // Delete any autosave
        let autosave = Autosave()
        if autosave.exists() {
            autosave.delete()
        }
        // Delete any pending notifications
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        // Reset Pomodoro time
        getPomodoroTime()
    }

    func formatTime() {
        /// Format time for stop watch clock
        let hours = secondsElapsed / 3600
        let hoursString = (hours < 10) ? "0\(hours)" : "\(hours)"
        let minutes = (secondsElapsed % 3600) / 60
        let minutesString = (minutes < 10) ? "0\(minutes)" : "\(minutes)"
        let seconds = secondsElapsed % 60
        let secondsString = (seconds < 10) ? "0\(seconds)" : "\(seconds)"
        timeElapsedFormatted = hoursString + ":" + minutesString + ":" + secondsString
        
        // Stop pomodoro timer if time is up
        if pomodoro && secondsElapsed == 0 {
            stop()
            TaskTagsInput.sharedInstance.text = ""
            TimerHelper.sharedInstance.onStop(context: persistenceController.container.viewContext, taskStopTime: Date.now)
            
            // Show notification
            registerLocal(notificationType: "pomodoro")
        }
    }
    
    func getIdleTime() -> Int {
        /// Get user's idle time
        let usbInfoAsString = IORegistryEntryCreateCFProperty(usbInfoRaw, kIOHIDIdleTimeKey as CFString, kCFAllocatorDefault, 0)
        let usbInfoVal: CFTypeRef = usbInfoAsString!.takeUnretainedValue()
        let idleTime = Int("\(usbInfoVal)")
        let idleTimeSecs = idleTime! / 1000000000
        return idleTimeSecs
    }
    
    func checkUserIdle() {
        /// Check if user is idle
        let selectedIdle = idleLimit * 60
        let idleTimeSecs = getIdleTime()
        
        // Find out if user is idle or back from being idle
        if idleTimeSecs < selectedIdle && idleTimeReached && !idleNotified {
            // User is back - show idle message
            idleNotified = true
            resumeFromIdle()
        } else if idleTimeSecs >= selectedIdle && !idleTimeReached {
            // User is idle
            idleTimeReached = true
            idleStartTime = Date.now.addingTimeInterval(Double(-selectedIdle))
        }
    }
    
    func resumeFromIdle() {
        /// Runs when user comes back after being idle
        let resumeTime = Date.now
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .short
        howLongIdle = formatter.string(from: idleStartTime, to: resumeTime)!
        
        // Show notification
        registerLocal(notificationType: "idle")

        // Open idle dialog in ContentView
        showingAlert = true
    }
    
    func resetIdle() {
        /// Reset all Idle properties
        idleNotified = false
        idleTimeReached = false
        showingAlert = false
        // Remove pending idle notifications
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }
}
