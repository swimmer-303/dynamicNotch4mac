import SwiftUI
import DynamicNotchKit

@main
struct DynamicNotch4MacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
} 