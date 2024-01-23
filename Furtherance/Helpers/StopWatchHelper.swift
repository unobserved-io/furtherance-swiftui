//
//  StopWatchHelper.swift
//  Furtherance
//
//  Created by Ricky Kresslein on 1/8/24.
//

import SwiftUI
import UserNotifications

@Observable
class StopWatchHelper {
    let persistenceController = PersistenceController.shared
    
    var isRunning: Bool = false
    var stopTime: Date = .distantFuture
    var startTime: Date = .now
    var showingIdleAlert: Bool = false
    
    var showingIdleAlertBinding: Binding<Bool> {
        Binding(
            get: { self.showingIdleAlert },
            set: { self.showingIdleAlert = $0 }
        )
    }
    
    @ObservationIgnored var minuteTimer = Timer()
    @ObservationIgnored var oneSecondTimer = Timer()
    @ObservationIgnored var idleNotified: Bool = false
    @ObservationIgnored var idleTimeReached: Bool = false
    @ObservationIgnored var idleStartTime: Date = .now
    @ObservationIgnored var idleLength: String = ""
    @ObservationIgnored var timeAtSleep: Date = .now
    @ObservationIgnored var idleAtSleep: Int = 0
    @ObservationIgnored var dockBadgeFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.maximumUnitCount = 2
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        return formatter
    }()
    
    @ObservationIgnored @AppStorage("idleDetect") private var idleDetect = false
    @ObservationIgnored @AppStorage("idleLimit") private var idleLimit = 6
    @ObservationIgnored @AppStorage("pomodoro") private var pomodoro = false
    @ObservationIgnored @AppStorage("pomodoroTime") private var pomodoroTime = 25
    @ObservationIgnored @AppStorage("showIconBadge") private var showIconBadge = false
    
#if os(macOS)
    let usbInfoRaw: io_service_t = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOHIDSystem"))
#endif
    
    func start( /* liveActivity: Bool = false */ ) {
        /// Start running the timer
        isRunning = true
        startTime = .now
        
        if pomodoro {
            stopTime = Calendar.current.date(byAdding: .second, value: (pomodoroTime * 60) + 1, to: startTime) ?? Date.now
            let pomodoroEndTimer = Timer(fireAt: stopTime, interval: 0, target: self, selector: #selector(pomodoroEndTasks), userInfo: nil, repeats: false)
            RunLoop.main.add(pomodoroEndTimer, forMode: .common)
            registerLocal(notificationType: "pomodoro")
        }
 
#if os(macOS)
        // One minute timer for autosave
        DispatchQueue.main.async {
            self.minuteTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                Autosave().write()
            }
        }

        // One second timer for idle detection and icon badge updating
        setOneSecondTimer()
        
        // Set computer sleep observers
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleepListener(_:)), name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleepListener(_:)), name: NSWorkspace.didWakeNotification, object: nil)
#endif
    }
    
    func stop() {
        /// Stop running the timer
        minuteTimer.invalidate()
        oneSecondTimer.invalidate()
        isRunning = false
        startTime = .now
        stopTime = .distantFuture
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
#if os(macOS)
        resetIdle()
        NSApp.dockTile.badgeLabel = nil
        
        // Destroy sleep observers
        NSWorkspace.shared.notificationCenter.removeObserver(self, name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.removeObserver(self, name: NSWorkspace.didWakeNotification, object: nil)
#endif
        
        // Delete any autosave
        let autosave = Autosave()
        if autosave.exists() {
            autosave.delete()
        }
    }
    
#if os(iOS)
    func resume() {
        /// Resume from a previously running timer
        isRunning = true
        
        if pomodoro {
            stopTime = Calendar.current.date(byAdding: .second, value: (pomodoroTime * 60) + 1, to: startTime) ?? Date.now
            if Date.now < stopTime {
                let pomodoroEndTimer = Timer(fireAt: stopTime, interval: 0, target: self, selector: #selector(pomodoroEndTasks), userInfo: nil, repeats: false)
                RunLoop.main.add(pomodoroEndTimer, forMode: .common)
                registerLocal(notificationType: "pomodoro")
            } else {
                pomodoroEndTasks()
            }
        }
    }
#endif
    
    func registerLocal(notificationType: String) {
        /// Register notification handler
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
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
    
    func scheduleLocalPomodoroNotification() {
        /// Set up notifications for Pomodoro timer
        let content = UNMutableNotificationContent()
        content.title = "Time's up!"
        content.body = "It's time to take a break."
        content.categoryIdentifier = "pomodoro"
        content.sound = UNNotificationSound.default
        content.relevanceScore = 1.0
        content.interruptionLevel = UNNotificationInterruptionLevel.active
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(pomodoroTime * 60), repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleLocalIdleNotification() {
        /// Setup notifications for when user comes back from being idle
        let content = UNMutableNotificationContent()
        content.title = "You have been idle for \(idleLength)"
        content.body = "Open Furtherance to continue or discard the idle time."
        content.categoryIdentifier = "idle"
        content.sound = UNNotificationSound.default
        content.relevanceScore = 1.0
        content.interruptionLevel = UNNotificationInterruptionLevel.active
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    @objc private func pomodoroEndTasks() {
        let recordedStopTime = stopTime
        stop()
        TaskTagsInput.sharedInstance.text = ""
        TimerHelper.sharedInstance.onStop(taskStopTime: recordedStopTime)
    }
    
#if os(macOS)
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
        if idleTimeSecs < selectedIdle, idleTimeReached, !idleNotified {
            // User is back - show idle message
            idleNotified = true
            resumeFromIdle()
        } else if idleTimeSecs >= selectedIdle, !idleTimeReached {
            // User is idle
            idleTimeReached = true
            idleStartTime = Date.now.addingTimeInterval(Double(-selectedIdle))
        }
    }
    
    func resumeFromIdle() {
        /// Runs when user comes back after being idle
        // Check if an idle alert is already showing to make sure this only happens once
        if !showingIdleAlert {
            let resumeTime = Date.now
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.unitsStyle = .short
            idleLength = formatter.string(from: idleStartTime, to: resumeTime)!
            
            // Show notification
            registerLocal(notificationType: "idle")

            // Open idle dialog in ContentView
            showingIdleAlert = true
        }
    }
    
    func resetIdle() {
        /// Reset all Idle properties
        idleNotified = false
        idleTimeReached = false
        showingIdleAlert = false
        // Remove pending idle notifications
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }
    
    func setOneSecondTimer() {
        if idleDetect || showIconBadge {
            DispatchQueue.main.async {
                self.minuteTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    if self.idleDetect {
                        self.checkUserIdle()
                    }
                    
                    if self.showIconBadge {
                        if self.pomodoro {
                            NSApp.dockTile.badgeLabel = self.dockBadgeFormatter.string(from: abs(Date.now.timeIntervalSince(self.stopTime)))
                        } else {
                            NSApp.dockTile.badgeLabel = self.dockBadgeFormatter.string(from: Date.now.timeIntervalSince(self.startTime))
                        }
                    }
                }
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
#endif
}
