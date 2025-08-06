import SwiftUI
import AppKit
import DynamicNotchKit
import UniformTypeIdentifiers
import CoreLocation
import EventKit

class AppDelegate: NSObject, NSApplicationDelegate, CLLocationManagerDelegate, ObservableObject {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var mouseTrackingTimer: Timer?
    var positionMonitoringTimer: Timer?
    var isNotchVisible = false
    var currentNotch: Any?
    var isProcessing = false
    var lastShowTime: Date = Date.distantPast
    
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
    

    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        startMouseTracking()
        setupPermissions()
        startDragDetection()
        loadReminders()
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "display", accessibilityDescription: "Dynamic Notch")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 350, height: 500)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: ContentView(appDelegate: self))
    }
    
    @objc func togglePopover() {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(nil)
            } else {
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
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
                            print("🔥 HIDING NOTCH - Mouse left notch area")
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
        // 🔥 THROTTLE: Prevent rapid multiple calls
        let now = Date()
        if now.timeIntervalSince(lastShowTime) < 0.5 {
            print("🔥 THROTTLING: Too soon since last show, ignoring")
            return
        }
        lastShowTime = now
        
        guard !isProcessing else { 
            print("🔥 ALREADY PROCESSING, IGNORING SHOW FILE TRAY")
            return 
        }
        
        // 🔥 FORCE CLOSE ANY EXISTING NOTCH FIRST
        if isNotchVisible || currentNotch != nil {
            print("🔥 FORCE CLOSING EXISTING NOTCH BEFORE SHOWING FILE TRAY")
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
            
            print("🔥 DYNAMIC NOTCH EXPANDED - ENSURING DROP TARGET...")
            
            // Force the notch to be the top-most window and accept drops
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.forceNotchToFront()
            }
            
            // Give it a moment to position itself, then try gentle correction
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("🔥 ATTEMPTING GENTLE POSITION CORRECTION...")
                self.gentlePositionCorrection()
            }
        }
    }
    
    func forceCloseCurrentNotch() {
        print("🔥 FORCE CLOSING CURRENT NOTCH - State: visible=\(isNotchVisible), processing=\(isProcessing), currentNotch=\(currentNotch != nil)")
        
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
        
        print("🔥 FORCE CLOSE COMPLETE")
    }
    
    func hideNotch() {
        guard isNotchVisible else { return }
        guard !isProcessing else { return }
        
        print("🔥 HIDING NOTCH NORMALLY")
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
    
    func setupPermissions() {
        print("🔐 REQUESTING PERMISSIONS...")
        
        // Location permissions
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // 🔥 REQUEST REMINDERS PERMISSION
        eventStore.requestAccess(to: .reminder) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ REMINDERS PERMISSION GRANTED")
                    self.loadReminders()
                } else {
                    print("❌ REMINDERS PERMISSION DENIED: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
        
        // 🔥 REQUEST CALENDAR PERMISSION  
        eventStore.requestAccess(to: .event) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ CALENDAR PERMISSION GRANTED")
                    self.loadUpcomingEvents()
                } else {
                    print("❌ CALENDAR PERMISSION DENIED: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    func startDragDetection() {
        print("🔥 STARTING BULLETPROOF DRAG DETECTION!")
        
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
        
        print("🔥 DRAG DETECTION ARMED AND READY!")
    }
    
    func handleMouseEvent(_ event: NSEvent) {
        switch event.type {
        case .leftMouseDown:
            // Reset drag state when mouse goes down
            if isDraggingFiles {
                print("🔥 MOUSE DOWN - RESETTING DRAG STATE")
                setDragState(false)
            }
        case .leftMouseDragged:
            // Check if this is a file drag
            detectFileDrag()
        case .leftMouseUp:
            // End drag state when mouse is released
            if isDraggingFiles {
                print("🔥 MOUSE UP - ENDING DRAG")
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
            print("🔥 FILE DRAG DETECTED FROM PASTEBOARD!")
            setDragState(true)
            return
        }
        
        // Alternative method: Check if Finder is frontmost and mouse is being dragged
        if let frontmostApp = NSWorkspace.shared.frontmostApplication {
            if frontmostApp.bundleIdentifier == "com.apple.finder" {
                print("🔥 DRAG FROM FINDER DETECTED!")
                setDragState(true)
                return
            }
        }
        
        // Another method: Check current mouse location and movement
        let currentEvent = NSApp.currentEvent
        
        if currentEvent?.type == .leftMouseDragged {
            print("🔥 MOUSE DRAG DETECTED - ASSUMING FILE DRAG!")
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
                print("🔥 PASTEBOARD CHANGE WITH FILES DETECTED!")
                if !isDraggingFiles {
                    setDragState(true)
                }
            }
        }
    }
    
    func setDragState(_ dragging: Bool) {
        if isDraggingFiles != dragging {
            print("🔥 SETTING DRAG STATE TO: \(dragging)")
            isDraggingFiles = dragging
            
            if dragging {
                // IMMEDIATELY show the notch with File Tray when dragging starts!
                print("🔥 DRAG STARTED - FORCING NOTCH TO APPEAR WITH FILE TRAY!")
                Task { @MainActor in
                    await forceShowFileTray()
                }
            } else {
                // When drag ends, update content if notch is visible
                if isNotchVisible {
                    print("🔥 DRAG ENDED - UPDATING NOTCH CONTENT")
        Task { @MainActor in
                        await updateNotchContent()
                    }
                }
            }
        }
    }
    
    @MainActor
    func forceShowFileTray() async {
        print("🔥 FORCE SHOWING FILE TRAY!")
        
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
        
        print("🔥 FILE TRAY FORCED TO SHOW!")
    }
    
    @MainActor
    func updateNotchContent() async {
        print("🔥 UPDATING NOTCH CONTENT - FORCE CLOSING FIRST")
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
        // 🔥 THROTTLE: Prevent rapid multiple calls
        let now = Date()
        if now.timeIntervalSince(lastShowTime) < 0.5 {
            print("🔥 THROTTLING: Too soon since last show, ignoring")
            return
        }
        lastShowTime = now
        
        guard !isProcessing else { 
            print("🔥 ALREADY PROCESSING, IGNORING SHOW DYNAMIC CONTENT")
            return 
        }
        
        // 🔥 FORCE CLOSE ANY EXISTING NOTCH FIRST
        if isNotchVisible || currentNotch != nil {
            print("🔥 FORCE CLOSING EXISTING NOTCH BEFORE SHOWING DYNAMIC CONTENT")
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
            
            print("🔥 DYNAMIC CONTENT NOTCH EXPANDED - ENSURING DROP TARGET...")
            
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
        print("🔥 FORCING NOTCH TO FRONT FOR DROPS...")
        
        // Force app to be frontmost
        NSApp.activate(ignoringOtherApps: true)
        
        // Find and aggressively promote notch windows
        for window in NSApp.windows {
            if window.isVisible && window.contentView != nil {
                print("🔥 PROMOTING WINDOW TO DROP TARGET: \(window)")
                
                // AGGRESSIVE window promotion for drops
                window.level = .popUpMenu  // Even higher than modalPanel
                window.orderFrontRegardless()
                window.makeKeyAndOrderFront(nil)
                
                // Enable drag and drop
                window.registerForDraggedTypes([.fileURL, .URL, .string])
                
                // Make it the key window
                window.makeKey()
                
                print("🔥 WINDOW PROMOTED - Level: \(window.level.rawValue), Key: \(window.isKeyWindow)")
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
                print("🔥 CHECKING WINDOW: \(window), Frame: \(window.frame)")
                
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
                        print("🔥 GENTLE CORRECTION: Moving from (\(currentX), \(currentY)) to (\(desiredX), \(desiredY))")
                        window.setFrameOrigin(NSPoint(x: desiredX, y: desiredY))
                        window.level = .popUpMenu  // Use higher level
                        window.orderFrontRegardless()
                    } else {
                        print("🔥 POSITION OK: Window at (\(currentX), \(currentY)) is close enough to target (\(desiredX), \(desiredY))")
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
    
    func loadReminders() {
        print("📝 LOADING ACTIVE REMINDERS...")
        let predicate = eventStore.predicateForReminders(in: nil)
        eventStore.fetchReminders(matching: predicate) { reminders in
            if let reminders = reminders {
                DispatchQueue.main.async {
                    // Filter for active (incomplete) reminders only
                    self.reminders = reminders.filter { !$0.isCompleted }
                    print("📝 LOADED \(self.reminders.count) ACTIVE REMINDERS")
                }
            }
        }
    }
    
    func loadUpcomingEvents() {
        print("📅 LOADING UPCOMING EVENTS...")
        
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
            
            print("📅 LOADED \(self.upcomingEvents.count) UPCOMING EVENTS")
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
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