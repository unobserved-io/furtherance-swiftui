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
    static let shared = StopWatchHelper()
    
    var isRunning: Bool = false
    var stopTime: Date = .distantFuture
    var startTime: Date = .now
    var showingIdleAlert: Bool = false
    var showingPomodoroEndedAlert: Bool = false
    var showingPomodoroIntermissionEndedAlert: Bool = false
    var pomodoroExtended: Bool = false
    var pomodoroOnBreak: Bool = false
    var pomodoroSessions: Int = 0
    
    var showingIdleAlertBinding: Binding<Bool> {
        Binding(
            get: { self.showingIdleAlert },
            set: { self.showingIdleAlert = $0 }
        )
    }
    
    var showingPomodoroEndedAlertBinding: Binding<Bool> {
        Binding(
            get: { self.showingPomodoroEndedAlert },
            set: { self.showingPomodoroEndedAlert = $0 }
        )
    }
    
    var showingPomodoroIntermissionEndedAlertBinding: Binding<Bool> {
        Binding(
            get: { self.showingPomodoroIntermissionEndedAlert },
            set: { self.showingPomodoroIntermissionEndedAlert = $0 }
        )
    }
    
    @ObservationIgnored var oneMinuteTimer = Timer()
    @ObservationIgnored var oneSecondTimer = Timer()
    @ObservationIgnored var pomodoroEndTimer = Timer()
    @ObservationIgnored var idleNotified: Bool = false
    @ObservationIgnored var idleTimeReached: Bool = false
    @ObservationIgnored var idleStartTime: Date = .now
    @ObservationIgnored var idleLength: String = ""
    @ObservationIgnored var timeAtSleep: Date = .now
    @ObservationIgnored var idleAtSleep: Int = 0
    @ObservationIgnored var intermissionTime: Int = 0
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
    @ObservationIgnored @AppStorage("pomodoroMoreTime") private var pomodoroMoreTime = 5
    @ObservationIgnored @AppStorage("pomodoroIntermissionTime") private var pomodoroIntermissionTime = 5
    @ObservationIgnored @AppStorage("pomodoroBigBreak") private var pomodoroBigBreak = false
    @ObservationIgnored @AppStorage("pomodoroBigBreakInterval") private var pomodoroBigBreakInterval = 4
    @ObservationIgnored @AppStorage("pomodoroBigBreakLength") private var pomodoroBigBreakLength = 25
    @ObservationIgnored @AppStorage("ptIsExtended") private var ptIsExtended: Bool = false
    @ObservationIgnored @AppStorage("ptStopTime") private var ptStopTime: TimeInterval = Date.now.timeIntervalSinceReferenceDate
    
#if os(macOS)
    let usbInfoRaw: io_service_t = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOHIDSystem"))
#endif
    
    func start(at startTime: Date = .now /* liveActivity: Bool = false */ ) {
        /// Start running the timer
        isRunning = true
        self.startTime = startTime
        initiatePomodoroTimer()
        
#if os(macOS)
        // One minute timer for autosave
        setOneMinuteTimer()
        
        // One second timer for idle detection and icon badge updating
        setOneSecondTimer()
        
        // Set computer sleep observers
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleepListener(_:)), name: NSWorkspace.willSleepNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleepListener(_:)), name: NSWorkspace.didWakeNotification, object: nil)
#endif
    }
    
    func stop() {
        /// Stop running the timer
        oneMinuteTimer.invalidate()
        oneSecondTimer.invalidate()
        isRunning = false
        startTime = .now
        invalidatePomodoroTimer()
        
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
            stopTime = Calendar.current.date(byAdding: .second, value: pomodoroTime * 60, to: startTime) ?? Date.now
            if Date.now < stopTime {
                pomodoroEndTimer = Timer(fireAt: stopTime, interval: 0, target: self, selector: #selector(showPomodoroTimesUpAlert), userInfo: nil, repeats: false)
                RunLoop.main.add(pomodoroEndTimer, forMode: .common)
            } else {
                showPomodoroTimesUpAlert()
            }
        }
    }
    
    func resumeIntermission() {
        pomodoroExtended = false
        pomodoroOnBreak = true
        isRunning = true
        
        stopTime = Calendar.current.date(byAdding: .minute, value: intermissionTime, to: startTime) ?? Date.now
        pomodoroEndTimer = Timer(fireAt: stopTime, interval: 0, target: self, selector: #selector(showPomodoroIntermissionEndedAlert), userInfo: nil, repeats: false)
        RunLoop.main.add(pomodoroEndTimer, forMode: .common)
        EarliestPomodoroTime.shared.setTimer()
    }
    
    func resumeExtended() {
        pomodoroExtended = true
        isRunning = true
        stopTime = Date(timeIntervalSinceReferenceDate: ptStopTime)
        pomodoroEndTimer = Timer(fireAt: stopTime, interval: 0, target: self, selector: #selector(showPomodoroTimesUpAlert), userInfo: nil, repeats: false)
        RunLoop.main.add(pomodoroEndTimer, forMode: .common)
    }
#endif
    
    func initiatePomodoroTimer() {
        if pomodoro {
            pomodoroSessions += 1
            // TODO: Replace this with .minute?
            stopTime = Calendar.current.date(byAdding: .second, value: pomodoroTime * 60, to: startTime) ?? Date.now
            pomodoroEndTimer = Timer(fireAt: stopTime, interval: 0, target: self, selector: #selector(showPomodoroTimesUpAlert), userInfo: nil, repeats: false)
            RunLoop.main.add(pomodoroEndTimer, forMode: .common)
            registerLocal(notificationType: "pomodoro")
            EarliestPomodoroTime.shared.setTimer()
        }
    }
    
    func invalidatePomodoroTimer() {
        pomodoroEndTimer.invalidate()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        stopTime = .distantFuture
        pomodoroOnBreak = false
        EarliestPomodoroTime.shared.invalidateTimer()
    }
    
    func updatePomodoroTimer() {
        invalidatePomodoroTimer()
        initiatePomodoroTimer()
    }
    
    func pomodoroMoreMinutes() {
        pomodoroExtended = true
        ptIsExtended = true
        stopTime = Calendar.current.date(byAdding: .minute, value: pomodoroMoreTime, to: .now) ?? Date.now
        ptStopTime = stopTime.timeIntervalSinceReferenceDate
        pomodoroEndTimer = Timer(fireAt: stopTime, interval: 0, target: self, selector: #selector(showPomodoroTimesUpAlert), userInfo: nil, repeats: false)
        RunLoop.main.add(pomodoroEndTimer, forMode: .common)
        registerLocal(notificationType: "pomodoro")
    }
        
    func pomodoroStartIntermission() {
        pomodoroExtended = false
        pomodoroOnBreak = true
        isRunning = true
        startTime = .now
        
        // One second timer for icon badge updating
        #if os(macOS)
            setOneSecondTimer()
        #endif
        
        intermissionTime = {
            if self.pomodoroBigBreak, self.pomodoroSessions % self.pomodoroBigBreakInterval == 0 {
                return self.pomodoroBigBreakLength
            } else {
                return self.pomodoroIntermissionTime
            }
        }()
        stopTime = Calendar.current.date(byAdding: .minute, value: intermissionTime, to: .now) ?? Date.now
        pomodoroEndTimer = Timer(fireAt: stopTime, interval: 0, target: self, selector: #selector(showPomodoroIntermissionEndedAlert), userInfo: nil, repeats: false)
        RunLoop.main.add(pomodoroEndTimer, forMode: .common)
        registerLocal(notificationType: "pomodoroIntermissionEnded")
        EarliestPomodoroTime.shared.setTimer()
    }
    
    @objc
    func showPomodoroIntermissionEndedAlert() {
        showingPomodoroIntermissionEndedAlert = true
    }
    
    @objc
    func showPomodoroTimesUpAlert() {
        showingPomodoroEndedAlert = true
    }

    func registerLocal(notificationType: String) {
        /// Register notification handler
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                if notificationType == "idle" {
                    self.scheduleLocalIdleNotification()
                } else if notificationType == "pomodoro" {
                    self.scheduleLocalPomodoroNotification()
                } else if notificationType == "pomodoroIntermissionEnded" {
                    self.scheduleLocalPomodoroIntermissionEndedNotification()
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
    
    func scheduleLocalPomodoroIntermissionEndedNotification() {
        /// Set up notifications for Pomodoro Intermission Ended timer
        let content = UNMutableNotificationContent()
        content.title = "Break's over!"
        content.body = "Time to get back to work."
        content.categoryIdentifier = "pomodoroIntermissionEnded"
        content.sound = UNNotificationSound.default
        content.relevanceScore = 1.0
        content.interruptionLevel = UNNotificationInterruptionLevel.active
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(pomodoroIntermissionTime * 60), repeats: false)

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
    
    func setOneMinuteTimer() {
        DispatchQueue.main.async {
            self.oneMinuteTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                Autosave().write()
            }
        }
    }
    
    func setOneSecondTimer() {
        if idleDetect || showIconBadge {
            DispatchQueue.main.async {
                self.oneSecondTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    if self.idleDetect, !self.pomodoroOnBreak {
                        self.checkUserIdle()
                    }
                    
                    if self.showIconBadge, !self.showingPomodoroEndedAlert {
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
                timeAtSleep = Date.now
                idleAtSleep = getIdleTime()
                idleStartTime = timeAtSleep.addingTimeInterval(Double(-idleAtSleep))
            } else if aNotification.name == NSWorkspace.didWakeNotification {
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
