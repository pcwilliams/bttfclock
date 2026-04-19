import SwiftUI

/// Root view: owns the persistent `CityStore` and the ticking
/// `ClockViewModel`, and assembles the Time Circuits display.
///
/// Layout differs by platform:
///
/// - **iOS:** clock centred between spacers with a gear button beneath
///   it. The enclosure is capped at `maxWidth: 700` with horizontal
///   inset so on wide-screen layouts (iPad landscape) it doesn't blow
///   up absurdly.
/// - **macOS:** the enclosure fills the entire window — the parent
///   scene's `.defaultSize` is picked to match the clock's natural
///   aspect ratio, so there's no letterboxing and no on-screen chrome.
///   Settings is reached via the app menu (`⌘,`) instead of a gear
///   button.
///
/// `showSettings` is owned by `BttfclockApp` so the macOS menu command
/// can toggle it; the sheet presentation lives here on both platforms.
struct ContentView: View {
    @StateObject private var store = CityStore()
    @StateObject private var clock = ClockViewModel(frozenDate: LaunchArgs.frozenDate())
    @Binding var showSettings: Bool

    var body: some View {
        platformBody
            .onAppear {
                // Launch-arg override runs *after* @StateObject has loaded
                // from UserDefaults, so `-cities` always wins over whatever
                // was persisted last session.
                if let override = LaunchArgs.cityIdsOverride() {
                    let cities = override.compactMap { CityCatalog.city(withId: $0) }
                    if !cities.isEmpty {
                        store.replace(with: cities)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(store)
            }
    }

    @ViewBuilder
    private var platformBody: some View {
        #if os(macOS)
        TimeCircuitsView(
            cities: store.selected,
            readouts: clock.readouts(for: store.selected)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        #else
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                TimeCircuitsView(
                    cities: store.selected,
                    readouts: clock.readouts(for: store.selected)
                )
                .padding(.horizontal, 14)
                .frame(maxWidth: 700)
                Spacer(minLength: 0)
                settingsButton
            }
        }
        #endif
    }

    private var settingsButton: some View {
        Button {
            showSettings = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "gearshape.fill")
                Text("CITIES")
                    .font(.system(size: 11, weight: .heavy, design: .default).width(.expanded))
                    .kerning(2)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color(red: 0.14, green: 0.14, blue: 0.12))
            .foregroundStyle(Color(red: 0.92, green: 0.92, blue: 0.88))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
        .padding(.bottom, 30)
        .accessibilityIdentifier("openSettings")
    }
}

/// Parses command-line arguments passed via `xcrun simctl launch` /
/// `xcrun devicectl ... process launch`. Each flag is optional and each
/// override is applied in `ContentView.onAppear`, after persisted state
/// has loaded — so overrides always win.
///
/// | Flag          | Effect                                         |
/// |---------------|------------------------------------------------|
/// | `-frozendate` | Pin the clock at an ISO8601 instant.           |
/// | `-cities`     | Replace selected cities (comma-sep slugs).     |
/// | `-settings`   | Open the settings sheet at launch.             |
enum LaunchArgs {
    /// Parses `-frozendate <iso>` using a progression of formatters
    /// (plain ISO8601, with fractional seconds, explicit `yyyy-MM-dd'T'
    /// HH:mm:ssZZZZZ`) so any reasonable human-typed value works. Returns
    /// nil if absent or unparseable.
    static func frozenDate() -> Date? {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-frozendate"), idx + 1 < args.count else {
            return nil
        }
        let value = args[idx + 1]
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if let d = formatter.date(from: value) { return d }
        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = fallback.date(from: value) { return d }
        let basic = DateFormatter()
        basic.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        basic.locale = Locale(identifier: "en_US_POSIX")
        return basic.date(from: value)
    }

    static func openSettingsAtLaunch() -> Bool {
        ProcessInfo.processInfo.arguments.contains("-settings")
    }

    /// Parses `-cities a,b,c` into raw slugs. Caller resolves each slug
    /// against `CityCatalog`; unknown slugs are silently dropped.
    static func cityIdsOverride() -> [String]? {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-cities"), idx + 1 < args.count else {
            return nil
        }
        let raw = args[idx + 1]
        let ids = raw.split(separator: ",").map { String($0) }
        return ids.isEmpty ? nil : ids
    }
}
