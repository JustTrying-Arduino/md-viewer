import SwiftUI
import UniformTypeIdentifiers

@main
struct MD_ViewerApp: App {
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup(for: URL.self) { $url in
            ContentView(url: url)
                .onOpenURL { incoming in
                    guard MarkdownFileTypes.isMarkdown(incoming) else { return }
                    if url == nil {
                        url = incoming
                    } else if url != incoming {
                        openWindow(value: incoming)
                    }
                }
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
            CommandMenu("Find") {
                FindCommand()
                FindNextCommand()
                FindPreviousCommand()
            }
        }
    }
}
