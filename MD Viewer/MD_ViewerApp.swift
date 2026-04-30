import SwiftUI
import UniformTypeIdentifiers

@main
struct MD_ViewerApp: App {
    var body: some Scene {
        WindowGroup(for: URL.self) { $url in
            ContentView(url: url)
        }
        .handlesExternalEvents(matching: ["*"])
        .commands {
            CommandGroup(replacing: .newItem) {
                OpenFileCommand()
            }
            CommandGroup(after: .saveItem) {
                SaveFileCommand()
            }
            CommandMenu("View") {
                ToggleModeCommand()
            }
        }
    }
}
