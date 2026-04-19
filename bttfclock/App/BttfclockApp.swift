import SwiftUI

/// App entry point. Dark colour scheme is forced because the Time
/// Circuits enclosure only reads correctly against a dark surround —
/// there's no light-mode variant of the design.
///
/// On macOS the `WindowGroup` opens at a size whose aspect ratio matches
/// the clock's natural proportions (three stacked rows of ~5:1 each
/// with minimal padding → roughly 1.55:1 overall). The settings sheet
/// is triggered from a replaced **Settings…** menu item bound to `⌘,`
/// so the window itself can stay free of gear-button chrome.
///
/// The `showSettings` state is owned here rather than in `ContentView`
/// so the menu command can poke it — the App-level `.commands` block
/// doesn't have access to `ContentView`'s internal `@State`.
@main
struct BttfclockApp: App {
    @State private var showSettings: Bool = LaunchArgs.openSettingsAtLaunch()

    var body: some Scene {
        WindowGroup {
            ContentView(showSettings: $showSettings)
                .preferredColorScheme(.dark)
                #if os(macOS)
                .frame(minWidth: 360, minHeight: 230)
                #endif
        }
        #if os(macOS)
        .defaultSize(width: 520, height: 335)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {
                    showSettings = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        #endif
    }
}
