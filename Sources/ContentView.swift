import SwiftUI
import DynamicNotchKit
import UniformTypeIdentifiers
import CoreLocation
import EventKit

struct ContentView: View {
    @State private var draggedFile: URL?
    
    let appDelegate: AppDelegate
    
    var body: some View {
        VStack(spacing: 16) {
            Text("🌟 Dynamic Notch Settings")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Notch Display Options:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Show Time", isOn: Binding(
                        get: { appDelegate.showTime },
                        set: { appDelegate.showTime = $0 }
                    ))
                    
                    Toggle("Show Weather", isOn: Binding(
                        get: { appDelegate.showWeather },
                        set: { appDelegate.showWeather = $0 }
                    ))
                    
                    Toggle("Show Reminders", isOn: Binding(
                        get: { appDelegate.showReminders },
                        set: { appDelegate.showReminders = $0 }
                    ))
                    
                    Toggle("Show File Count", isOn: Binding(
                        get: { appDelegate.showFileCount },
                        set: { appDelegate.showFileCount = $0 }
                    ))
                }
                .padding(.leading)
            }
            
                VStack(alignment: .leading, spacing: 8) {
                Text("File Management:")
                        .font(.headline)
                    
                    Text("Drag files here to add them to your File Tray")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .frame(height: 60)
                        .overlay(
                            VStack {
                                Image(systemName: "folder.badge.plus")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                Text("Drop files here")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        )
                        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                            handleFileDrop(providers: providers)
                            return true
                        }
                    
                    if !appDelegate.fileTrayItems.isEmpty {
                        Text("Files in tray: \(appDelegate.fileTrayItems.count)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Usage:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("🌟 Dynamic notch shows time, weather, reminders")
                    .font(.caption)
                    .foregroundColor(.green)
                Text("📁 Drag files to switch to file tray mode")
                    .font(.caption)
                    .foregroundColor(.blue)
                Text("Move mouse to top center of screen to activate")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 350, height: 450)
    }
    

    
    func handleFileDrop(providers: [NSItemProvider]) {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            appDelegate.addFileToTray(url)
                        }
                    }
                }
            }
        }
    }
    

    

}



struct DynamicContentView: View {
    let appDelegate: AppDelegate
    @State private var currentTime = Date()
    @State private var temperature = "72°F"
    @State private var timer: Timer?
    @State private var isDropTargeted = false
    @State private var selectedTab: Tab = .home
    
    enum Tab: String, CaseIterable {
        case home = "Home"
        case reminders = "Reminders"
        case calendar = "Calendar"
        case fileTray = "File Tray"
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .reminders: return "checklist"
            case .calendar: return "calendar"
            case .fileTray: return "folder.badge.plus"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab bar at the top
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.caption)
                            Text(tab.rawValue)
                        .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedTab == tab ? Color.blue.opacity(0.2) : Color.clear)
                        .foregroundColor(selectedTab == tab ? .blue : .secondary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            
            Divider()
                .padding(.horizontal, 8)
            
            // Content area based on selected tab
            Group {
                switch selectedTab {
                case .home:
                    HomeTabView(appDelegate: appDelegate, currentTime: currentTime, temperature: temperature)
                case .reminders:
                    RemindersTabView(appDelegate: appDelegate)
                case .calendar:
                    CalendarTabView(appDelegate: appDelegate)
                case .fileTray:
                    FileTrayTabView(appDelegate: appDelegate)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .frame(minHeight: 120)
        }
        .frame(width: 400, height: 180) // Much bigger notch!
        .background(isDropTargeted ? Color.blue.opacity(0.2) : Color(.windowBackgroundColor))
                .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isDropTargeted ? Color.blue : Color.clear, lineWidth: 3)
                )
                .overlay(
            // Show drop hint when dragging
            Group {
                if isDropTargeted {
                    VStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                        Text("Drop files here!")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(16)
                    .transition(.opacity)
                }
            }
        )
        .cornerRadius(16)
        .onDrop(of: [.fileURL, .url, .text], isTargeted: $isDropTargeted) { providers in
            print("🔥 DROP DETECTED with \(providers.count) providers")
            
            // Switch to file tray tab IMMEDIATELY
            selectedTab = .fileTray
            
            // Process EVERY provider with multiple methods
            for (index, provider) in providers.enumerated() {
                print("🔥 Processing provider \(index): \(provider)")
                print("🔥 Available types: \(provider.registeredTypeIdentifiers)")
                
                // Method 1: Try file URL
                if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                    provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                        print("🔥 Method 1 result: item=\(String(describing: item)), error=\(String(describing: error))")
                        self.processDroppedItem(item, appDelegate: appDelegate)
                    }
                }
                
                // Method 2: Try UTType.fileURL
                if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                        print("🔥 Method 2 result: item=\(String(describing: item)), error=\(String(describing: error))")
                        self.processDroppedItem(item, appDelegate: appDelegate)
                    }
                }
                
                // Method 3: Try any URL
                if provider.hasItemConformingToTypeIdentifier("public.url") {
                    provider.loadItem(forTypeIdentifier: "public.url", options: nil) { item, error in
                        print("🔥 Method 3 result: item=\(String(describing: item)), error=\(String(describing: error))")
                        self.processDroppedItem(item, appDelegate: appDelegate)
                    }
                }
                
                // Method 4: Brute force - try all available types
                for typeId in provider.registeredTypeIdentifiers {
                    provider.loadItem(forTypeIdentifier: typeId, options: nil) { item, error in
                        print("🔥 Method 4 (\(typeId)) result: item=\(String(describing: item)), error=\(String(describing: error))")
                        self.processDroppedItem(item, appDelegate: appDelegate)
                    }
                }
            }
            
            return true
        }
        .onChange(of: isDropTargeted) { targeted in
            if targeted {
                selectedTab = .fileTray
                appDelegate.setDragState(true)
            } else {
                // Reset drag state after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    appDelegate.setDragState(false)
                }
            }
        }
        .onAppear {
            startTimer()
            updateWeather()
            
            // 🔥 AUTO-SWITCH TO FILE TRAY IF DRAGGING FILES OR SHOWING FILE TRAY!
            if appDelegate.isDraggingFiles || appDelegate.isShowingFileTray {
                print("🔥 NOTCH APPEARED - FORCING FILE TRAY TAB! (dragging: \(appDelegate.isDraggingFiles), showingTray: \(appDelegate.isShowingFileTray))")
                selectedTab = .fileTray
            }
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: appDelegate.isDraggingFiles) { isDragging in
            // 🔥 AUTO-SWITCH TO FILE TRAY when drag starts!
            if isDragging {
                print("🔥 DRAG STATE CHANGED TO TRUE - AUTO-SWITCHING TO FILE TRAY!")
                selectedTab = .fileTray
            }
        }
        .onChange(of: appDelegate.isShowingFileTray) { showingTray in
            // 🔥 AUTO-SWITCH TO FILE TRAY when file tray mode is activated!
            if showingTray {
                print("🔥 FILE TRAY MODE ACTIVATED - FORCING FILE TRAY TAB!")
                selectedTab = .fileTray
            }
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: currentTime)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: currentTime)
    }
    
    private var weatherIcon: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        if hour >= 6 && hour < 18 {
            return "sun.max.fill"
        } else {
            return "moon.fill"
        }
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = Date()
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func updateWeather() {
        // Simulate weather data
        let temps = ["68°F", "72°F", "75°F", "70°F", "73°F"]
        temperature = temps.randomElement() ?? "72°F"
    }
    
    func processDroppedItem(_ item: Any?, appDelegate: AppDelegate) {
        guard let item = item else {
            print("🔥 Item is nil")
                        return
                    }
        
        print("🔥 Processing item of type: \(type(of: item))")
                    
                    var url: URL?
                    
        // Try different ways to extract URL
        if let urlItem = item as? URL {
                        url = urlItem
            print("🔥 Got URL directly: \(urlItem)")
        } else if let data = item as? Data {
            if let urlFromData = URL(dataRepresentation: data, relativeTo: nil) {
                url = urlFromData
                print("🔥 Got URL from data: \(urlFromData)")
            } else if let string = String(data: data, encoding: .utf8) {
                url = URL(string: string)
                print("🔥 Got URL from data string: \(string)")
            }
                    } else if let string = item as? String {
                        url = URL(string: string)
            print("🔥 Got URL from string: \(string)")
        } else if let nsUrl = item as? NSURL {
            url = nsUrl as URL
            print("🔥 Got URL from NSURL: \(nsUrl)")
                    }
                    
                    if let finalURL = url {
            print("🔥 SUCCESS! Final URL: \(finalURL)")
                        DispatchQueue.main.async {
                                appDelegate.addFileToTray(finalURL)
                print("🔥 ADDED TO TRAY: \(finalURL.lastPathComponent)")
            }
        } else {
            print("🔥 FAILED to extract URL from item: \(item)")
        }
    }
}

struct HomeTabView: View {
    let appDelegate: AppDelegate
    let currentTime: Date
    let temperature: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Time display
            if appDelegate.showTime {
                VStack(alignment: .leading, spacing: 2) {
                    Text(timeString)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(dateString)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Weather
            if appDelegate.showWeather {
                HStack(spacing: 6) {
                    Image(systemName: weatherIcon)
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text(temperature)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            // Quick stats
            HStack(spacing: 16) {
                if !appDelegate.reminders.isEmpty {
                    VStack(spacing: 2) {
                        Image(systemName: "checklist")
                            .font(.title2)
                            .foregroundColor(.green)
                        Text("\(appDelegate.reminders.count)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                
                if !appDelegate.fileTrayItems.isEmpty {
                    VStack(spacing: 2) {
                        Image(systemName: "folder.badge.plus")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text("\(appDelegate.fileTrayItems.count)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.top, 8)
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: currentTime)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: currentTime)
    }
    
    private var weatherIcon: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        if hour >= 6 && hour < 18 {
            return "sun.max.fill"
        } else {
            return "moon.fill"
        }
    }
}

struct RemindersTabView: View {
    let appDelegate: AppDelegate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if appDelegate.reminders.isEmpty {
        VStack(spacing: 8) {
                Image(systemName: "checklist")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("No active reminders")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(appDelegate.reminders.prefix(4), id: \.calendarItemIdentifier) { reminder in
                            HStack {
                                    Image(systemName: "circle")
                                    .font(.caption)
                                        .foregroundColor(.green)
                                
                                Text(reminder.title ?? "Untitled")
                                    .font(.caption)
                                    .lineLimit(1)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding(.top, 8)
    }
}

struct CalendarTabView: View {
    let appDelegate: AppDelegate
    @State private var currentDate = Date()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                .font(.title2)
                .foregroundColor(.blue)
            
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next 3 Hours")
                    .font(.headline)
                        .fontWeight(.semibold)
                    Text("Today: \(dayString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
            
            // 🔥 UPCOMING EVENTS IN NEXT 3 HOURS
            if appDelegate.upcomingEvents.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("No upcoming events")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(appDelegate.upcomingEvents.prefix(4), id: \.eventIdentifier) { event in
                            HStack(alignment: .top, spacing: 8) {
                                VStack(spacing: 2) {
                                    Text(eventTimeString(event.startDate))
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                    if event.isAllDay {
                                        Text("All Day")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(width: 50)
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(event.title)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                    
                                    if let location = event.location, !location.isEmpty {
                                        Text(location)
                                            .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                                    }
            }
            
            Spacer()
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding(.top, 8)
    }
    
    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentDate)
    }
    
    private var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: currentDate)
    }
    
    private func eventTimeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct FileTrayTabView: View {
    let appDelegate: AppDelegate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "folder.badge.plus")
                .font(.title2)
                .foregroundColor(.orange)
            
                Text("File Tray")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !appDelegate.fileTrayItems.isEmpty {
                    Button(action: {
                        appDelegate.fileTrayItems.removeAll()
                    }) {
                        Image(systemName: "trash")
                    .font(.caption)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if appDelegate.fileTrayItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.badge.plus")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("Drag files here to add them")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                } else {
                // Simplified file display for speed
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 8) {
                        ForEach(Array(appDelegate.fileTrayItems.enumerated()), id: \.offset) { index, file in
                            FastFileItemView(file: file, index: index, appDelegate: appDelegate)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(height: 80)
            }
        }
        .padding(.top, 8)
    }
}

// Optimized file item view for speed
struct FastFileItemView: View {
    let file: URL
    let index: Int
    let appDelegate: AppDelegate
    
    // Cache the icon and name for performance
    private var fileIcon: String {
        let ext = file.pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.richtext"
        case "txt", "md": return "doc.text"
        case "jpg", "jpeg", "png", "gif", "bmp": return "photo"
        case "mp4", "mov", "avi": return "video"
        case "mp3", "wav", "aac": return "music.note"
        case "zip", "rar", "7z": return "archivebox"
        case "app": return "app"
        case "dmg": return "externaldrive"
        default: return "doc"
        }
    }
    
    private var fileName: String {
        file.lastPathComponent
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: fileIcon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(fileName)
                .font(.caption2)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 60)
            
            Button(action: {
                appDelegate.removeFileFromTray(file)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
        .onDrag {
            // Simplified drag setup for speed
            let itemProvider = NSItemProvider()
            itemProvider.registerObject(file as NSURL, visibility: .all)
            return itemProvider
        }
    }
}

#Preview {
    ContentView(appDelegate: AppDelegate())
} 