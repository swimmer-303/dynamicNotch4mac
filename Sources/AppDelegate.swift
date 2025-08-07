import SwiftUI
import AppKit
import DynamicNotchKit
import UniformTypeIdentifiers
import CoreLocation
import EventKit
import os.log

// MARK: - App Errors
enum AppError: LocalizedError {
    case menuBarSetupFailed
    case notchCreationFailed
    case permissionDenied(String)
    case fileAccessError(String)
    case locationServicesUnavailable
    case calendarAccessFailed
    case remindersAccessFailed
    case criticalSystemError(String)
    
    var errorDescription: String? {
        switch self {
        case .menuBarSetupFailed:
            return "Failed to setup menu bar item"
        case .notchCreationFailed:
            return "Failed to create dynamic notch"
        case .permissionDenied(let permission):
            return "Permission denied for \(permission)"
        case .fileAccessError(let message):
            return "File access error: \(message)"
        case .locationServicesUnavailable:
            return "Location services are not available"
        case .calendarAccessFailed:
            return "Failed to access calendar data"
        case .remindersAccessFailed:
            return "Failed to access reminders data"
        case .criticalSystemError(let message):
            return "Critical system error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .menuBarSetupFailed:
            return "Try restarting the application. If the problem persists, contact support."
        case .notchCreationFailed:
            return "Check if your system supports the dynamic notch feature."
        case .permissionDenied(let permission):
            return "Grant \(permission) permission in System Preferences > Security & Privacy."
        case .fileAccessError:
            return "Check file permissions and try again."
        case .locationServicesUnavailable:
            return "Enable location services in System Preferences > Security & Privacy > Location Services."
        case .calendarAccessFailed:
            return "Grant calendar access in System Preferences > Security & Privacy > Calendar."
        case .remindersAccessFailed:
            return "Grant reminders access in System Preferences > Security & Privacy > Reminders."
        case .criticalSystemError:
            return "Restart the application. If the problem persists, contact support."
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, CLLocationManagerDelegate, ObservableObject {
    // MARK: - Properties
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var mouseTrackingTimer: Timer?
    var positionMonitoringTimer: Timer?
    var isNotchVisible = false
    var currentNotch: Any?
    var isProcessing = false
    var lastShowTime: Date = Date.distantPast
    
    // MARK: - Logging
    private let logger = Logger(subsystem: "com.dynamicnotch.app", category: "AppDelegate")
    
    // File tray
    @Published var fileTrayItems: [URL] = []
    var isDraggingFiles = false
    var isShowingFileTray = false
    
    // Dynamic content
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    let eventStore = EKEventStore()
    @Published var reminders: [EKReminder] = []
    @Published var upcomingEvents: [EKEvent] = []
    
    // Settings
    @Published var showTime = true
    @Published var showWeather = true
    @Published var showReminders = true
    @Published var showFileCount = true
    

    
    // MARK: - Application Lifecycle
    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("DynamicNotch4Mac starting up...")
        
        do {
            try setupMenuBar()
            startMouseTracking()
            setupPermissions()
            startDragDetection()
            loadReminders()
            logger.info("DynamicNotch4Mac setup completed successfully")
        } catch {
            logger.error("Failed to setup application: \(error.localizedDescription)")
            showErrorAlert("Failed to setup DynamicNotch4Mac", error.localizedDescription)
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        logger.info("DynamicNotch4Mac shutting down...")
        mouseTrackingTimer?.invalidate()
        positionMonitoringTimer?.invalidate()
        locationManager.stopUpdatingLocation()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            togglePopover()
        }
        return true
    }
    
    // MARK: - UI Setup
    func setupMenuBar() throws {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let button = statusItem?.button else {
            throw AppError.menuBarSetupFailed
        }
        
        button.image = NSImage(systemSymbolName: "display", accessibilityDescription: "Dynamic Notch")
        button.action = #selector(togglePopover)
        button.target = self
        
        // Create menu for additional options
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Settings", action: #selector(togglePopover), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About DynamicNotch4Mac", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        // Right-click shows menu, left-click shows popover
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem?.menu = menu
        
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 350, height: 500)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: ContentView(appDelegate: self))
        
        logger.info("Menu bar setup completed")
    }
    
    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "DynamicNotch4Mac"
        alert.informativeText = "Version 1.0.0\n\nA dynamic notch experience for your Mac that shows time, weather, reminders, and provides file management capabilities.\n\n© 2024 DynamicNotch4Mac"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc func quitApp() {
        logger.info("User requested app quit")
        NSApplication.shared.terminate(nil)
    }
    
    func showErrorAlert(_ title: String, _ message: String, recoverySuggestion: String? = nil) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .critical
            
            if let recovery = recoverySuggestion {
                alert.informativeText += "\n\n" + recovery
            }
            
            alert.addButton(withTitle: "OK")
            
            // Add "Open System Preferences" button for permission errors
            if message.contains("permission") || message.contains("access") {
                alert.addButton(withTitle: "Open System Preferences")
                let response = alert.runModal()
                
                if response == .alertSecondButtonReturn {
                    // Open System Preferences
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
                        NSWorkspace.shared.open(url)
                    }
                }
            } else {
                alert.runModal()
            }
        }
    }
    
    func handleError(_ error: AppError) {
        logger.error("App error occurred: \(error.localizedDescription)")
        showErrorAlert("Dynamic Notch Error", error.localizedDescription, recoverySuggestion: error.recoverySuggestion)
    }
    
    @objc func togglePopover() {
        guard let button = statusItem?.button else {
            logger.error("Failed to get status item button")
            return
        }
        
        // Handle right-click vs left-click
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            // Right-click: show context menu (handled automatically by statusItem?.menu)
            return
        }
        
        // Left-click: toggle popover
        if popover?.isShown == true {
            popover?.performClose(nil)
            logger.debug("Popover closed")
        } else {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            logger.debug("Popover opened")
        }
    }
    

    
    func startMouseTracking() {
        mouseTrackingTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            self.checkMouseInNotchArea()
        }
    }
    
    func checkMouseInNotchArea() {
        guard let screen = NSScreen.main else { return }
        guard !isProcessing else { return } // Prevent overlapping operations
        
        let mouseLocation = NSEvent.mouseLocation
        let screenFrame = screen.frame
        
        // 🔥 WHEN NOTCH IS VISIBLE - MATCH THE ACTUAL NOTCH SIZE!
        if isNotchVisible {
            // Detection area should match the actual notch size (400x180) plus some margin
            let notchWidth: CGFloat = 450    // Slightly wider than notch (400px)
            let notchHeight: CGFloat = 220   // Taller than notch (180px) to include area around it
            let hideDetectionX = (screenFrame.width - notchWidth) / 2
            let hideDetectionY = screenFrame.height - notchHeight - 10  // 10px from top
            
            let hideDetectionRect = NSRect(x: hideDetectionX, y: hideDetectionY, width: notchWidth, height: notchHeight)
            let isMouseInNotchArea = hideDetectionRect.contains(mouseLocation)
            
                                    // Only hide if mouse is COMPLETELY outside the notch area and not dragging
            if !isMouseInNotchArea && !isDraggingFiles {
                // Add a longer delay before hiding to prevent accidental closes
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    if !self.isDraggingFiles && self.isNotchVisible {
                        let currentMouse = NSEvent.mouseLocation
                        if !hideDetectionRect.contains(currentMouse) {
                            self.logger.debug("Hiding notch - Mouse left notch area")
                            self.hideNotch()
                        }
                    }
                }
            }
            
            // Check if we need to switch content type
            if !isProcessing {
                let needsSwitch = (isDraggingFiles && !isShowingFileTray) || (!isDraggingFiles && isShowingFileTray)
                if needsSwitch {
                    Task { @MainActor in
                        await updateNotchContent()
                    }
                }
            }
            
            return // Don't do show detection when notch is already visible
        }
        
        // 🔥 WHEN NOTCH IS HIDDEN - USE LARGER DETECTION AREA (for showing)
        let detectionWidth: CGFloat = 500  // Much wider detection area
        let notchHeight: CGFloat = 50      // Larger trigger area
        let menuBarHeight: CGFloat = 25    // Approximate menu bar height
        let notchY = screenFrame.height - notchHeight - 8  // Notch position (8px from top)
        
        // 🔥 EXCLUDE MENU BAR AREA - Detection area goes from BELOW menu bar to notch
        let detectionX = (screenFrame.width - detectionWidth) / 2
        let detectionY = notchY  // Start from notch position
        let detectionHeight = screenFrame.height - notchY - menuBarHeight  // Stop before menu bar
        
        let detectionRect = NSRect(x: detectionX, y: detectionY, width: detectionWidth, height: detectionHeight)
        
        // 🔥 MENU BAR EXCLUSION - Check if mouse is in menu bar area
        let menuBarRect = NSRect(x: 0, y: screenFrame.height - menuBarHeight, width: screenFrame.width, height: menuBarHeight)
        let isMouseInMenuBar = menuBarRect.contains(mouseLocation)
        
        let isMouseInNotch = detectionRect.contains(mouseLocation) && !isMouseInMenuBar
        
        // Show appropriate content when mouse is in DETECTION area
        if isMouseInNotch && !isNotchVisible && !isProcessing {
            if isDraggingFiles {
                showFileTray()
        } else {
                showDynamicContent()
            }
        }
    }
    
    func showFileTray() {
        // Throttle: Prevent rapid multiple calls
        let now = Date()
        if now.timeIntervalSince(lastShowTime) < 0.5 {
            logger.debug("Throttling: Too soon since last show, ignoring")
            return
        }
        lastShowTime = now
        
        guard !isProcessing else { 
            logger.debug("Already processing, ignoring show file tray")
            return 
        }
        
        // Force close any existing notch first
        if isNotchVisible || currentNotch != nil {
            logger.debug("Force closing existing notch before showing file tray")
            forceCloseCurrentNotch()
        }
        
        isProcessing = true
        isNotchVisible = true
        isShowingFileTray = true
        
        Task { @MainActor in
            defer { isProcessing = false }
            
            // 🔥 USE DYNAMICNOTCH BUT TRY MINIMAL INTERFERENCE
            let notch = DynamicNotch(hoverBehavior: []) {
                DynamicContentView(appDelegate: self)
            }
            
            currentNotch = notch
            await notch.expand()
            
            logger.debug("Dynamic notch expanded - ensuring drop target")
            
            // Force the notch to be the top-most window and accept drops
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.forceNotchToFront()
            }
            
            // Give it a moment to position itself, then try gentle correction
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.logger.debug("Attempting gentle position correction")
                self.gentlePositionCorrection()
            }
        }
    }
    
    func forceCloseCurrentNotch() {
        logger.debug("Force closing current notch - State: visible=\(self.isNotchVisible), processing=\(self.isProcessing), currentNotch=\(self.currentNotch != nil)")
        
        // Stop position monitoring immediately
        positionMonitoringTimer?.invalidate()
        positionMonitoringTimer = nil
        
        // Close any existing notch synchronously
        if let notch = currentNotch as? any DynamicNotchControllable {
            Task { @MainActor in
                await notch.hide()
            }
        }
        
        // Reset all state immediately
        currentNotch = nil
        isNotchVisible = false
        isShowingFileTray = false
        isProcessing = false
        
        // Give a brief moment for cleanup
        Thread.sleep(forTimeInterval: 0.1)
        
        logger.debug("Force close complete")
    }
    
    func hideNotch() {
        guard isNotchVisible else { return }
        guard !isProcessing else { return }
        
        logger.debug("Hiding notch normally")
        forceCloseCurrentNotch()
    }
    

    

    

    

    

    

    

    

    
    func addFileToTray(_ url: URL) {
        if !fileTrayItems.contains(url) {
            fileTrayItems.append(url)
        }
    }
    
    func removeFileFromTray(_ url: URL) {
        fileTrayItems.removeAll { $0 == url }
    }
    
    // MARK: - Permissions
    func setupPermissions() {
        logger.info("Requesting permissions...")
        
        // Location permissions
        setupLocationPermissions()
        
        // Calendar and Reminders permissions
        setupCalendarPermissions()
        setupRemindersPermissions()
    }
    
    private func setupLocationPermissions() {
        guard CLLocationManager.locationServicesEnabled() else {
            logger.error("Location services not enabled")
            handleError(.locationServicesUnavailable)
            return
        }
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            logger.warning("Location access denied or restricted")
            handleError(.permissionDenied("Location"))
        @unknown default:
            logger.warning("Unknown location authorization status")
        }
    }
    
    private func setupRemindersPermissions() {
        eventStore.requestAccess(to: .reminder) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.logger.info("Reminders permission granted")
                    self.loadReminders()
                } else {
                    let errorMessage = error?.localizedDescription ?? "Unknown error"
                    self.logger.error("Reminders permission denied: \(errorMessage)")
                    self.handleError(.remindersAccessFailed)
                }
            }
        }
    }
    
    private func setupCalendarPermissions() {
        eventStore.requestAccess(to: .event) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.logger.info("Calendar permission granted")
                    self.loadUpcomingEvents()
                } else {
                    let errorMessage = error?.localizedDescription ?? "Unknown error"
                    self.logger.error("Calendar permission denied: \(errorMessage)")
                    self.handleError(.calendarAccessFailed)
                }
            }
        }
    }
    
    // MARK: - Drag Detection
    func startDragDetection() {
        logger.info("Starting drag detection...")
        
        // BULLETPROOF METHOD 1: Monitor ALL mouse events
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp]) { event in
            DispatchQueue.main.async {
                self.handleMouseEvent(event)
            }
        }
        
        // BULLETPROOF METHOD 2: Monitor pasteboard changes (when files are being dragged)
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            DispatchQueue.main.async {
                self.checkPasteboardForDrag()
            }
        }
        
        // BULLETPROOF METHOD 3: Monitor for drag images being created
        NSEvent.addGlobalMonitorForEvents(matching: [.otherMouseDragged, .rightMouseDragged]) { event in
            DispatchQueue.main.async {
                self.detectFileDrag()
            }
        }
        
        logger.info("Drag detection initialized")
    }
    
    func handleMouseEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown:
            // Reset drag state when mouse goes down
            if isDraggingFiles {
                logger.debug("Mouse down - resetting drag state")
                setDragState(false)
            }
        case .leftMouseDragged:
            // Check if this is a file drag
            detectFileDrag()
        case .leftMouseUp:
            // End drag state when mouse is released
            if isDraggingFiles {
                logger.debug("Mouse up - ending drag")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.setDragState(false)
                }
            }
        default:
            break
        }
    }
    
    func detectFileDrag() {
        // Only proceed if we're not already detecting a drag
        guard !isDraggingFiles else { return }
        
        // Check if there's anything in the pasteboard that suggests file dragging
        let pasteboard = NSPasteboard.general
        let hasFiles = pasteboard.types?.contains(.fileURL) == true ||
                      pasteboard.types?.contains(.URL) == true ||
                      pasteboard.canReadObject(forClasses: [NSURL.self], options: nil)
        
        if hasFiles {
            logger.debug("File drag detected from pasteboard")
            setDragState(true)
            return
        }
        
        // Alternative method: Check if Finder is frontmost and mouse is being dragged
        if let frontmostApp = NSWorkspace.shared.frontmostApplication {
            if frontmostApp.bundleIdentifier == "com.apple.finder" {
                logger.debug("Drag from Finder detected")
                setDragState(true)
                return
            }
        }
        
        // Another method: Check current mouse location and movement
        let currentEvent = NSApp.currentEvent
        
        if currentEvent?.type == .leftMouseDragged {
            logger.debug("Mouse drag detected - assuming file drag")
            setDragState(true)
        }
    }
    
    func checkPasteboardForDrag() {
        // Continuously monitor pasteboard for file operations
        let pasteboard = NSPasteboard.general
        let changeCount = pasteboard.changeCount
        
        // Static variable to track changes
        struct PasteboardMonitor {
            static var lastChangeCount = 0
        }
        
        if changeCount != PasteboardMonitor.lastChangeCount {
            PasteboardMonitor.lastChangeCount = changeCount
            
            // Check if the new content includes files
            if pasteboard.types?.contains(.fileURL) == true ||
               pasteboard.types?.contains(.URL) == true {
                logger.debug("Pasteboard change with files detected")
                if !isDraggingFiles {
                    setDragState(true)
                }
            }
        }
    }
    
    func setDragState(_ dragging: Bool) {
        if isDraggingFiles != dragging {
            logger.debug("Setting drag state to: \(dragging)")
            isDraggingFiles = dragging
            
            if dragging {
                // IMMEDIATELY show the notch with File Tray when dragging starts!
                logger.debug("Drag started - showing file tray")
                Task { @MainActor in
                    await forceShowFileTray()
                }
            } else {
                // When drag ends, update content if notch is visible
                if isNotchVisible {
                    logger.debug("Drag ended - updating notch content")
        Task { @MainActor in
                        await updateNotchContent()
                    }
                }
            }
        }
    }
    
    // MARK: - Notch Management
    @MainActor
    func forceShowFileTray() async {
        logger.debug("Force showing file tray")
        
        // Hide current notch if any
        if let notch = currentNotch as? any DynamicNotchControllable {
            await notch.hide()
        }
        currentNotch = nil
        isNotchVisible = false
        
        // Brief delay then FORCE show file tray
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        // FORCE show the file tray regardless of mouse position
        showFileTray()
        
        logger.info("File tray displayed")
    }
    
    @MainActor
    func updateNotchContent() async {
        logger.debug("Updating notch content - force closing first")
        forceCloseCurrentNotch()
        
        // Brief delay then show appropriate content
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        if isDraggingFiles {
            showFileTray()
        } else {
            showDynamicContent()
        }
    }
    
    func showDynamicContent() {
        // Throttle: Prevent rapid multiple calls
        let now = Date()
        if now.timeIntervalSince(lastShowTime) < 0.5 {
            logger.debug("Throttling: Too soon since last show, ignoring")
            return
        }
        lastShowTime = now
        
        guard !isProcessing else { 
            logger.debug("Already processing, ignoring show dynamic content")
            return 
        }
        
        // Force close any existing notch first
        if isNotchVisible || currentNotch != nil {
            logger.debug("Force closing existing notch before showing dynamic content")
            forceCloseCurrentNotch()
        }
        
        isProcessing = true
        isNotchVisible = true
        isShowingFileTray = false
        
        Task { @MainActor in
            defer { isProcessing = false }
            
            // 🔥 USE DYNAMICNOTCH FOR DYNAMIC CONTENT TOO
            let notch = DynamicNotch(hoverBehavior: []) {
                DynamicContentView(appDelegate: self)
            }
            
            currentNotch = notch
            await notch.expand()
            
            logger.debug("Dynamic content notch expanded - ensuring drop target")
            
            // Force the notch to be the top-most window and accept drops
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.forceNotchToFront()
            }
            
            // Try gentle position correction
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.gentlePositionCorrection()
            }
        }
    }
    
    func startPositionMonitoring() {
        // Stop any existing timer
        positionMonitoringTimer?.invalidate()
        
        // Start monitoring position every 0.1 seconds while notch is visible
        positionMonitoringTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if self.isNotchVisible {
                self.forceCorrectPositioning()
            } else {
                // Stop monitoring when notch is not visible
                self.positionMonitoringTimer?.invalidate()
                self.positionMonitoringTimer = nil
            }
        }
    }
    
    func forceNotchToFront() {
        logger.debug("Forcing notch to front for drops")
        
        // Force app to be frontmost
        NSApp.activate(ignoringOtherApps: true)
        
        // Find and aggressively promote notch windows
        for window in NSApp.windows {
            if window.isVisible && window.contentView != nil {
                logger.debug("Promoting window to drop target: \(window)")
                
                // AGGRESSIVE window promotion for drops
                window.level = .popUpMenu  // Even higher than modalPanel
                window.orderFrontRegardless()
                window.makeKeyAndOrderFront(nil)
                
                // Enable drag and drop
                window.registerForDraggedTypes([.fileURL, .URL, .string])
                
                // Make it the key window
                window.makeKey()
                
                logger.debug("Window promoted - Level: \(window.level.rawValue), Key: \(window.isKeyWindow)")
            }
        }
        
        // Continue promoting every 0.5 seconds while notch is visible
        if isNotchVisible {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.isNotchVisible {
                    self.forceNotchToFront()
                }
            }
        }
    }
    
    func gentlePositionCorrection() {
        // Find the DynamicNotch window and gently adjust if needed
        for window in NSApp.windows {
            if window.isVisible && window.contentView != nil {
                let windowDescription = String(describing: window)
                let frameDescription = String(describing: window.frame)
                logger.debug("Checking window: \(windowDescription), Frame: \(frameDescription)")
                
                if let screen = NSScreen.main {
                    let screenFrame = screen.frame
                    let windowFrame = window.frame
                    
                    // Check if window is significantly off from where we want it
                    let desiredX = (screenFrame.width - windowFrame.width) / 2
                    let desiredY = screenFrame.height - windowFrame.height - 30  // 30px from top (more reasonable)
                    
                    let currentX = windowFrame.origin.x
                    let currentY = windowFrame.origin.y
                    
                    // Only adjust if it's way off (more than 50px in any direction)
                    if abs(currentX - desiredX) > 50 || abs(currentY - desiredY) > 100 {
                        logger.debug("Gentle correction: Moving from (\(currentX), \(currentY)) to (\(desiredX), \(desiredY))")
                        window.setFrameOrigin(NSPoint(x: desiredX, y: desiredY))
                        window.level = .popUpMenu  // Use higher level
                        window.orderFrontRegardless()
                    } else {
                        logger.debug("Position OK: Window at (\(currentX), \(currentY)) is close enough to target (\(desiredX), \(desiredY))")
                        // Still ensure high level even if position is OK
                        window.level = .popUpMenu
                        window.orderFrontRegardless()
                    }
                }
            }
        }
    }
    
    func forceCorrectPositioning() {
        // Keep the old function for now but make it less aggressive
        gentlePositionCorrection()
    }
    
    // MARK: - Data Loading
    func loadReminders() {
        logger.info("Loading reminders...")
        
        let predicate = eventStore.predicateForReminders(in: nil)
        eventStore.fetchReminders(matching: predicate) { reminders in
            DispatchQueue.main.async {
                if let reminders = reminders {
                    // Filter for active (incomplete) reminders only
                    self.reminders = reminders.filter { !$0.isCompleted }
                    self.logger.info("Loaded \(self.reminders.count) active reminders")
                } else {
                    self.logger.error("Failed to load reminders - no data returned")
                    self.handleError(.remindersAccessFailed)
                }
            }
        }
    }
    
    func loadUpcomingEvents() {
        logger.info("Loading upcoming events...")
        
        // Get events for the next 3 hours
        let now = Date()
        let threeHoursFromNow = Calendar.current.date(byAdding: .hour, value: 3, to: now) ?? now
        
        let predicate = eventStore.predicateForEvents(
            withStart: now,
            end: threeHoursFromNow,
            calendars: nil
        )
        
        let events = eventStore.events(matching: predicate)
        
        DispatchQueue.main.async {
            self.upcomingEvents = events.filter { event in
                // Only include events that haven't ended yet
                event.endDate > now
            }.sorted { event1, event2 in
                // Sort by start date
                event1.startDate < event2.startDate
            }
            
            self.logger.info("Loaded \(self.upcomingEvents.count) upcoming events")
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.error("Location error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }
    

    

} 