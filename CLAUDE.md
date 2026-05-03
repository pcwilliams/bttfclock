
# iOS Development Conventions

Native iOS apps built with Swift and SwiftUI. No storyboards, no external dependencies.

## Tech Stack

- **Language:** Swift 5
- **UI Framework:** SwiftUI (no storyboards, no XIBs)
- **Minimum Target:** iOS 17.0+ (some projects use iOS 18.0+)
- **Xcode:** 16+
- **Device:** iPhone only (`TARGETED_DEVICE_FAMILY = 1`)
- **Orientation:** Portrait only
- **Dependencies:** Zero external dependencies — pure Apple frameworks only (SwiftUI, MapKit, CoreLocation, Photos, CryptoKit, Swift Charts, etc.)

## Architecture

All projects follow **MVVM** with SwiftUI's reactive data binding:

- **View models** are `ObservableObject` classes with `@Published` properties, observed via `@StateObject` in views
- **Views** are declarative SwiftUI — no UIKit unless wrapping a system controller (e.g. `SFSafariViewController`)
- **Services/API clients** use the `actor` pattern for thread safety
- **Networking** uses native `URLSession` with `async/await` — no external HTTP libraries
- **View models** are annotated `@MainActor` when they drive UI state

## Project Structure

Each project follows this standard layout:

```
ProjectName/
├── ProjectName.xcodeproj/
├── CLAUDE.md                    # Developer reference
├── README.md                    # User-facing documentation
├── architecture.html            # Interactive Mermaid.js architecture diagrams
├── tutorial.html                # Build narrative with prompts and responses
└── ProjectName/
    ├── App/
    │   ├── ProjectNameApp.swift # @main entry point
    │   └── ContentView.swift    # Root view / navigation
    ├── Models/                  # Data model structs and SwiftData @Models
    ├── Views/                   # SwiftUI views
    │   └── Components/          # Reusable view components
    ├── Services/                # API clients, managers, business logic
    ├── ViewModels/              # ObservableObject state management
    ├── Extensions/              # Formatters and helpers
    └── Assets.xcassets/
        ├── AppIcon.appiconset/  # 1024x1024 icons (standard, dark, tinted)
        └── AccentColor.colorset/
```

Smaller projects (e.g. Where) may flatten this into fewer files — simplicity over ceremony.

## Xcode Project File (project.pbxproj)

Projects are created and maintained by writing `project.pbxproj` directly, not via the Xcode GUI. When adding new Swift files to a target that doesn't use file system sync, register in four places:

1. **PBXBuildFile section** — build file entry
2. **PBXFileReference section** — file reference entry
3. **PBXGroup** — add to the appropriate group's `children` list
4. **PBXSourcesBuildPhase** — add build file to the target's Sources phase

ID patterns vary per project but follow a consistent incrementing convention within each project. Test targets may use `PBXFileSystemSynchronizedRootGroup` (Xcode 16+), meaning test files are auto-discovered.

## Build Verification

Always verify the build after any code change:

```bash
xcodebuild -project ProjectName.xcodeproj -scheme ProjectName \
  -destination 'generic/platform=iOS' build \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```

A clean result ends with `** BUILD SUCCEEDED **`. Fix any errors before considering a task complete.

## Testing

```bash
xcodebuild -project ProjectName.xcodeproj -scheme ProjectName \
  -destination 'platform=iOS Simulator,name=iPhone 16' test \
  CODE_SIGNING_ALLOWED=NO
```

- Use **in-memory containers** for SwiftData tests (fast, isolated)
- Use the **Swift Testing framework** (`import Testing`, `@Test`, `#expect()`) for newer projects
- **Extract pure decision logic as `internal static` methods** with explicit parameters so tests can inject values directly — avoid testing through singletons, UserDefaults, or system frameworks
- Test files that use Foundation types must `import Foundation` alongside `import Testing`

### Simulator Testing with Launch Arguments

For apps with multiple modes or views, add **launch argument parsing** so visual testing can be fully automated from the command line — never try to tap simulator UI with AppleScript (it's unreliable). Parse `ProcessInfo.processInfo.arguments` in the root view to accept flags like `-mode <value>`.

**Launch arguments must override persisted settings.** When an app uses `@AppStorage` or `UserDefaults`, launch arguments must be applied *after* persistence loads (e.g. in `onAppear`) so they take priority. Return optionals from launch-arg parsers (nil = no override).

```swift
// In ContentView or root view
private static func initialMode() -> Mode {
    let args = ProcessInfo.processInfo.arguments
    if let idx = args.firstIndex(of: "-mode"), idx + 1 < args.count {
        return Mode(rawValue: args[idx + 1]) ?? .default
    }
    return .default
}
```

Then test each mode from the command line:

```bash
xcrun simctl install booted path/to/App.app
xcrun simctl privacy booted grant microphone com.bundle.id  # if needed
xcrun simctl terminate booted com.bundle.id
xcrun simctl launch booted com.bundle.id -- -mode someMode
sleep 2
xcrun simctl io booted screenshot /tmp/screenshot.png
```

This pattern was established in ShiftingSands and adopted in Spectrum. Every new project with multiple visual states should support this from the start.

### Bundled Test Files for Hardware-Dependent Features

When a feature depends on hardware input (microphone, GPS, camera), create **bundled test files** that exercise the same code path in the simulator:

- **Audio**: Generate WAV files with Python — pure tones (440Hz sine), multi-tone sequences, periodic beats. Bundle and play via `-testfile <name>` launch argument.
- **Location**: Bundle JSON files with known GPS coordinates for map-based testing.
- **Images**: Bundle sample photos with known EXIF data for photo-processing features.

The DSP/processing pipeline shouldn't know or care whether input comes from hardware or a test file.

```python
import wave, struct, math
sample_rate = 44100
samples = []
for freq, duration in [(261.63, 1.5), (329.63, 1.5), (440.0, 1.5), (0, 1.0)]:
    for i in range(int(sample_rate * duration)):
        t = i / sample_rate
        value = 0.7 * math.sin(2 * math.pi * freq * t) if freq > 0 else 0
        samples.append(int(value * 32767))
with wave.open('test.wav', 'w') as f:
    f.setnchannels(1); f.setsampwidth(2); f.setframerate(sample_rate)
    f.writeframes(struct.pack('<' + 'h' * len(samples), *samples))
```

### Diagnostic Logging for Algorithm Debugging

For complex algorithms (DSP, ML, signal processing), add **structured diagnostic logging** gated behind a launch argument:

```swift
// In the engine/service
static var verboseLogging = false

// In the algorithm
if Self.verboseLogging {
    alog("PITCH DBG: acPeak=\(peak) lag=\(lag) freq=\(freq)Hz")
}

// In ContentView onAppear
if args.contains("-pitchlog") { AudioEngine.verboseLogging = true }
```

**What to log:** algorithm confidence metrics, which branch/threshold was taken, input characteristics, state changes.

**What NOT to log every frame:** raw sample values, full array contents, unchanged state.

Use change-only logging for display state and periodic logging for diagnostics (every Nth frame).

### Reading Logs from Simulator and Device

```bash
# Simulator: read the app's Documents directory
CONTAINER=$(xcrun simctl get_app_container booted com.bundle.id data)
cat "$CONTAINER/Documents/app.log"

# Clear log before a test run
> "$CONTAINER/Documents/app.log"

# Device: stream logs via:
xcrun devicectl device syslog --device <udid>
```

### Performance Testing in the DSP/Rendering Pipeline

For real-time processing, measure execution time against the time budget:

```swift
let start = CACurrentMediaTime()
// ... processing ...
let elapsed = CACurrentMediaTime() - start
dspTimingSum += elapsed
dspTimingCount += 1
if elapsed > dspTimingMax { dspTimingMax = elapsed }
if dspTimingCount % 100 == 0 {
    let avgMs = (dspTimingSum / Double(dspTimingCount)) * 1000
    let maxMs = dspTimingMax * 1000
    let budgetMs = Double(bufferSize) / Double(sampleRate) * 1000
    alog("DSP PERF: avg=\(avgMs)ms, max=\(maxMs)ms, budget=\(budgetMs)ms")
}
```

Budget = time between callbacks (e.g. 2048 samples at 44.1kHz = 46.4ms). If average exceeds ~50% of budget, optimise before adding features.

### Simulator vs Device Differences

The simulator does NOT replicate everything. Always test on device for:

- **Microphone input** (simulator has no mic hardware)
- **GPS / CoreLocation** (simulator uses simulated locations)
- **Audio session behaviour** (`.playAndRecord` fails on simulator — use `.playback` with `#if targetEnvironment(simulator)`)
- **Sample rates** (simulator often uses 44.1kHz, device may use 48kHz — parameterise, don't hardcode)
- **Real-world signal characteristics** (voice has harmonics, vibrato, breath noise that pure test tones lack)
- **Hardware format edge cases** (0 Hz sample rate, 0 input channels — detect and alert the user)

## Key Patterns

### Persistence

- **SwiftData** for structured app data (e.g. PillRecord)
- **UserDefaults / @AppStorage** for preferences, settings, and cache
- **iOS Keychain** for API credentials and secrets (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`)
- **JSON encoding** in UserDefaults for lightweight structured data (e.g. portfolio, saved places)

### Networking

- **Graceful degradation:** The app should work with reduced functionality when API calls fail. Isolate independent API calls in separate `do/catch` blocks so one failure doesn't take down the others
- **Task cancellation:** Cancel in-flight tasks before starting new ones. Check `Task.isCancelled` before publishing results
- **Debouncing:** Use 0.8-second debounce for rapid user interactions (e.g. map panning) to prevent API spam
- **Caching:** Cache API responses with TTLs in UserDefaults (e.g. 5-min for quotes, 30-min for historical data)

### Concurrency

- **Actor-based services** for thread-safe API clients
- **`async let` for parallel fetching** of independent data
- Wrap work in an unstructured `Task` inside `.refreshable` to prevent SwiftUI from cancelling structured concurrency children when `@Published` properties trigger re-renders
- **`Task.detached(.utility)`** for background work like photo library scanning
- **Swift 6 concurrency:** Use `guard let self else { return }` in detached task closures; copy mutable `var` to `let` before `await MainActor.run`

### Timers

- Prefer **one-shot `DispatchWorkItem`** over polling `Timer.publish`
- Avoid always-running timers — schedule on demand, cancel on completion

### SwiftUI

- **`.id()` modifier** on views for animated identity changes (e.g. month transitions)
- **GeometryReader** for proportional layouts
- **Asymmetric slide transitions** with tracked direction state
- **NavigationStack** with `.toolbar` and `.sheet` for settings
- **`.refreshable`** for pull-to-refresh
- **Segmented pickers** for mode selection (chart periods, map styles, etc.)
- **@AppStorage** for persisting UI preferences across launches
- **`.contentShape(Rectangle())`** for full-row tap targets

### GPU rendering — 3D surfaces, terrain, waterfalls, landscapes

For any feature that renders a 2D value field as a lit, animated 3D surface (frequency × time, day × hour, X × Y × any-Z, ridgelines, terrain), use the **`3dsurface`** skill. It captures the canonical Metal pipeline, mesh, camera math, lighting, smoothing, and animation patterns extracted from HeartMap and Spectrum — including the non-obvious decisions (fixed colour scales, smoothing-decoupled-from-colour, face normals, locked camera) that make a surface read as *stunning* rather than just correct.

### Apple Health / HealthKit

For any feature that reads heart rate, steps, workouts, sleep, or other Apple Health data, use the **`healthkit`** skill. It captures the actor-based service shape, authorization (single combined prompt; read perms aren't queryable), the optimized fetch patterns (per-month queries, server-side bucketing via `HKStatisticsCollectionQuery + .cumulativeSum`, parallel `async let`), the three-phase load (disk-cache seed → current-month refresh → background stream), the empty-result fallback to demo data, infinity-safe JSON disk caching, workout activity type → label/symbol mapping, and entitlements/provisioning gotchas (wildcard profiles can't carry HealthKit).

For *clinical interpretation* of that data — fitness scores, resting heart rate calculations, AHA active-minute zones, age-adjusted scoring, evidence-based step thresholds — use the **`health`** skill. It's platform-agnostic (useful in web dashboards too) and always carries an explicit "not medical advice" disclaimer.

## App Icons

Generated programmatically using **Python/Pillow** — not designed in a graphics tool. Three variants at 1024x1024:

- **Standard** (light mode)
- **Dark** (dark mode)
- **Tinted** (greyscale for tinted mode)

Referenced in `Contents.json` with `luminosity` appearance variants. Use `Image.new("RGB", ...)` not `"RGBA"` — iOS strips alpha for app icons, causing compositing artefacts with semi-transparent overlays.

## Documentation

Each project includes four living documents that must be kept up to date:

### CLAUDE.md (developer reference)

Must be updated whenever: a file, model, view, or service is added/removed; an architectural decision is made; a new API is integrated; a non-obvious bug is fixed; build configuration or project structure changes.

This is the single source of truth for project context. A future session should be able to read CLAUDE.md and understand the entire project without exploring the codebase.

### README.md (user-facing)

Must be updated whenever: features are added/changed/removed; setup instructions change; project structure changes significantly; screenshots become outdated.

### architecture.html (architecture diagrams)

Interactive Mermaid.js diagrams. Must be updated whenever: view hierarchy changes; data flow changes; new major subsystems are added.

Use `graph TD` for readability. Load Mermaid.js from CDN. Apply the shared dark theme with CSS custom properties and project-appropriate accent colours.

### tutorial.html (build narrative)

A step-by-step record of how the app was built. Must be updated whenever: a significant new feature is added; a major refactor is made; an interesting problem is solved through iterative prompting.

**Prompt tone:** Use collaborative language — "Could we try...", "How about...", "I'd love it if..." rather than imperatives. Use "I'm seeing..." for problems rather than assertive declarations.

### Formatting conventions

- Plain Markdown in `.md` files (no inline HTML except README badges). Images use `![alt](src)` syntax, not `<img>` tags
- HTML docs use a shared dark theme with CSS custom properties and Mermaid.js loaded from CDN
- HTML docs include a hero screenshot in a phone-frame wrapper (black background, rounded corners, drop shadow) below the title/badges

## Common Gotchas

- **Keychain: always delete before add** to avoid `errSecDuplicateItem`
- **SwiftUI `.refreshable` cancels structured concurrency** — wrap network calls in an unstructured `Task`
- **Wikimedia geosearch caps at 10,000m radius** — clamp before sending
- **Wikipedia disambiguation pages** — filter out articles where extract contains "may refer to"

---


# macOS Development Conventions

Native macOS apps built with Swift and SwiftUI. No storyboards, no external dependencies.

## Tech Stack

- **Language:** Swift 5
- **UI Framework:** SwiftUI (no storyboards, no XIBs; AppKit only when wrapping a system controller)
- **Minimum Target:** macOS 14.0+
- **Xcode:** 16+
- **Dependencies:** Zero external dependencies — pure Apple frameworks only (SwiftUI, AppKit, AVFoundation, MusicKit, etc.)

## Architecture

All projects follow **MVVM** with SwiftUI's reactive data binding:

- **View models** are `ObservableObject` classes with `@Published` properties, observed via `@StateObject` in views
- **Views** are declarative SwiftUI — no AppKit unless wrapping a system controller
- **Services/API clients** use the `actor` pattern for thread safety
- **Networking** uses native `URLSession` with `async/await` — no external HTTP libraries
- **View models** are annotated `@MainActor` when they drive UI state

## Project Structure

Each project follows this standard layout:

```
ProjectName/
├── ProjectName.xcodeproj/
├── CLAUDE.md                    # Developer reference
├── README.md                    # User-facing documentation
├── architecture.html            # Interactive Mermaid.js architecture diagrams
├── tutorial.html                # Build narrative with prompts and responses
└── ProjectName/
    ├── App/
    │   ├── ProjectNameApp.swift # @main entry point
    │   └── ContentView.swift    # Root view / navigation
    ├── Models/                  # Data model structs and SwiftData @Models
    ├── Views/                   # SwiftUI views
    │   └── Components/          # Reusable view components
    ├── Services/                # API clients, managers, business logic
    ├── ViewModels/              # ObservableObject state management
    ├── Extensions/              # Formatters and helpers
    └── Assets.xcassets/
        ├── AppIcon.appiconset/  # 1024x1024 icon
        └── AccentColor.colorset/
```

## Xcode Project File (project.pbxproj)

Projects are created and maintained by writing `project.pbxproj` directly, not via the Xcode GUI. When adding new Swift files to a target that doesn't use file system sync, register in four places:

1. **PBXBuildFile section** — build file entry
2. **PBXFileReference section** — file reference entry
3. **PBXGroup** — add to the appropriate group's `children` list
4. **PBXSourcesBuildPhase** — add build file to the target's Sources phase

## Build Verification

Always verify the build after any code change:

```bash
xcodebuild -project ProjectName.xcodeproj -scheme ProjectName \
  -destination 'generic/platform=macOS' build \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -5
```

A clean result ends with `** BUILD SUCCEEDED **`. Fix any errors before considering a task complete.

## Testing

```bash
xcodebuild -project ProjectName.xcodeproj -scheme ProjectName \
  -destination 'platform=macOS' test \
  CODE_SIGNING_ALLOWED=NO
```

- Use **in-memory containers** for SwiftData tests (fast, isolated)
- Use the **Swift Testing framework** (`import Testing`, `@Test`, `#expect()`) for newer projects
- **Extract pure decision logic as `internal static` methods** with explicit parameters so tests can inject values directly
- Test files that use Foundation types must `import Foundation` alongside `import Testing`
- macOS apps run directly on the Mac — test and iterate without a simulator

## Key Patterns

### Persistence

- **SwiftData** for structured app data
- **UserDefaults / @AppStorage** for preferences, settings, and cache
- **macOS Keychain** for API credentials and secrets (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`)
- **JSON encoding** in UserDefaults for lightweight structured data

### Networking

- **Graceful degradation:** The app should work with reduced functionality when API calls fail. Isolate independent API calls in separate `do/catch` blocks
- **Task cancellation:** Cancel in-flight tasks before starting new ones. Check `Task.isCancelled` before publishing results
- **Debouncing:** Use 0.8-second debounce for rapid user interactions to prevent API spam
- **Caching:** Cache API responses with TTLs in UserDefaults

### Concurrency

- **Actor-based services** for thread-safe API clients
- **`async let` for parallel fetching** of independent data
- Wrap work in an unstructured `Task` inside `.refreshable` to prevent SwiftUI from cancelling structured concurrency children
- **`Task.detached(.utility)`** for background work
- **Swift 6 concurrency:** Use `guard let self else { return }` in detached task closures; copy mutable `var` to `let` before `await MainActor.run`

### Timers

- Prefer **one-shot `DispatchWorkItem`** over polling `Timer.publish`
- Avoid always-running timers — schedule on demand, cancel on completion

### SwiftUI (macOS)

- **NavigationSplitView** for sidebar + detail layouts
- **`.commands`** modifier for menu bar items
- **`NSOpenPanel` / `NSSavePanel`** wrapped in `NSViewControllerRepresentable` for file pickers
- **`@AppStorage`** for persisting UI preferences across launches
- **`.contentShape(Rectangle())`** for full-row tap targets
- **`Settings { ... }`** scene for the Preferences window

## App Icons

Generated programmatically using **Python/Pillow** — not designed in a graphics tool. Single variant at 1024x1024 (macOS does not use dark/tinted app icon variants the same way iOS does).

Referenced in `Contents.json`. Use `Image.new("RGB", ...)` not `"RGBA"`.

## Documentation

Each project includes four living documents that must be kept up to date:

### CLAUDE.md (developer reference)

Must be updated whenever: a file, model, view, or service is added/removed; an architectural decision is made; a new API is integrated; a non-obvious bug is fixed; build configuration or project structure changes.

### README.md (user-facing)

Must be updated whenever: features are added/changed/removed; setup instructions change; screenshots become outdated.

### architecture.html (architecture diagrams)

Interactive Mermaid.js diagrams. Use `graph TD` for readability. Load Mermaid.js from CDN. Apply the shared dark theme.

### tutorial.html (build narrative)

A step-by-step record of how the app was built. Use collaborative prompt tone — "Could we try...", "How about...", "I'd love it if..."

### Formatting conventions

- Plain Markdown in `.md` files. Images use `![alt](src)` syntax, not `<img>` tags
- HTML docs use a shared dark theme with CSS custom properties and Mermaid.js loaded from CDN

## Multi-platform iOS+macOS apps

A single Xcode target can build for both `iphoneos`/`iphonesimulator` and `macosx`. ~99% of the code is platform-neutral; the differences are funneled through a small set of typealiases plus a handful of narrowly-scoped `#if` blocks. Pattern proven on a SceneKit solar-system app — see SolarSystem's `Extensions/Platform.swift`.

### Platform.swift typealiases

In `Extensions/Platform.swift`:

| Typealias | iOS | macOS |
|-----------|-----|-------|
| `PlatformColor` | `UIColor` | `NSColor` |
| `PlatformImage` | `UIImage` | `NSImage` |
| `PlatformView` | `UIView` | `NSView` |
| `PlatformViewRepresentable` | `UIViewRepresentable` | `NSViewRepresentable` |

Plus `makePlatformImage(cgImage:size:)` and `cgImage(from:)` helpers for `UIImage`↔`NSImage` bridging where construction differs.

**Rule**: outside `Platform.swift` (and a handful of files that genuinely need `#if`), never write `UIColor`/`UIImage`/UIKit-typed names directly. Use the `Platform…` aliases and most code stays one-line.

The places that *do* still need `#if canImport(UIKit)` in practice:
- Gesture recognisers (UIKit and AppKit APIs diverge meaningfully)
- The frame-tick loop (different display-link constructors)
- SwiftUI modifiers that exist on only one platform (`.statusBarHidden`, `navigationBarTitleDisplayMode`, `topBarTrailing`, etc.)

### Frame-tick loop

Use `CADisplayLink` on both platforms — just constructed differently:

- **iOS**: `CADisplayLink(target: self, selector: ...)` on the main run loop, display-synchronised 30–60 Hz.
- **macOS 14+**: `scnView.displayLink(target: self, selector: ...)` — the NSView-bound form. Binds to whichever display the window is on so ticks stay synced to that screen's VBlank.

**Don't try `Timer.scheduledTimer` on macOS as a substitute.** It produces visible ~1-per-second stutters because Timer's cadence drifts in and out of phase with the 60 Hz refresh. Only the real display link is reliable.

Because the macOS display link needs an SCNView/NSView to bind to, the start-animation request can arrive before the view is connected (SwiftUI's `onAppear` can fire before `makeNSView` completes). Park the request in a `pendingAnimationStart` flag and re-issue once the view's `didSet` runs.

### Gesture conventions (macOS vs iOS)

The AppKit Y axis is inverted relative to UIKit. macOS pan/orbit handlers must flip `dy` (e.g. `lastPoint.y - translation.y`) so "drag up = look up" stays consistent with iOS. All actual camera/transform maths stays shared between platforms — only the input plumbing differs.

Typical macOS gesture map for a 3D scene:

| Input | Action | Implementation |
|-------|--------|----------------|
| Left-mouse drag | Pan target | `NSPanGestureRecognizer` with `buttonMask = 0x1` |
| Right-mouse drag | Orbit | `NSPanGestureRecognizer` with `buttonMask = 0x2` |
| Trackpad pinch | Zoom | `NSMagnificationGestureRecognizer` |
| Scroll wheel / 2-finger scroll | Zoom | Subclass overriding `scrollWheel(with:)` |
| Single click | Select | `NSClickGestureRecognizer` (`numberOfClicks = 1`) |
| Double click | Reset | `NSClickGestureRecognizer` (`numberOfClicks = 2`) |

### SCNVector3 component types

`SCNVector3.x/y/z` is `Float` on iOS but `CGFloat` on macOS. Two helpers in `SCNVector3+Math.swift` (or equivalent) hide the gap:

- `SCNVector3(_ x: Double, _ y: Double, _ z: Double)` — build a vector from `Double` components.
- `SCNVector3.adding(_ dx: Double, _ dy: Double, _ dz: Double) -> SCNVector3` — offset by `Double` deltas, returning a new vector.

Use these wherever you previously wrote `SCNVector3(x, y, z)` with `Float` arithmetic — one-line call sites compile on both platforms.

### Launching with arguments (Debug from DerivedData)

Same `ProcessInfo.processInfo.arguments` parsing pattern as iOS, but the launcher is different:

```bash
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/<Project>-*/Build/Products/Debug/<Project>.app -maxdepth 0)
open -n "$APP_PATH" --args -mode someMode -timeScale 5000
```

`open -n` launches a fresh instance each time (`-n` for "new"); drop it to reuse the running copy. The `--args` flag feeds everything after it into `ProcessInfo.processInfo.arguments`. For Release-built apps installed to `/Applications`, just point `open -n` at the bundle there.

## Common Gotchas

- **Keychain: always delete before add** to avoid `errSecDuplicateItem`
- **SwiftUI `.refreshable` cancels structured concurrency** — wrap network calls in an unstructured `Task`
- **Sandbox entitlements:** macOS apps are sandboxed by default — ensure `com.apple.security.files.user-selected.read-write` or similar entitlements are set for file access
- **MusicKit / AppleScript:** `MusicKit` is the modern API for Apple Music access; `AppleScript` bridging via `NSAppleScript` is a fallback for operations MusicKit doesn't cover
- **`Timer.scheduledTimer` is not a frame clock** — it drifts in and out of phase with 60 Hz refresh, producing ~1 Hz stutters. Use `scnView.displayLink(target:selector:)` (macOS 14+) for any per-frame work bound to a SceneKit view; for non-SceneKit frame work, use `CVDisplayLink` directly.
- **AppKit Y axis is inverted vs UIKit** — flip `dy` in any pan / drag handler shared with iOS code, otherwise the "drag up = look up" convention reverses on macOS.

---

# BTTFClock — Claude Code Project Reference

An iOS + macOS clock that renders the current time in three configurable
world cities on a faithful recreation of the Back to the Future DeLorean
**Time Circuits** — three rectangular grey tiles on a dark chassis, each
with red/green/amber LED segments, grey-on-red caption plates, AM/PM
stacked indicator lamps, and a colon that step-ticks in sync with
wall-clock seconds.

## Owner

- **Developer:** pwilliams (GitHub: pcwilliams)
- **Development Team:** (your Apple Developer Team ID)
- **Device:** iPhone 16 Pro
- **Bundle ID:** `com.pwilliams.bttfclock`
- **Display name:** Time Circuits

## Platforms

Single target, shared binary across:

- **iOS 17+** — iPhone portrait (`TARGETED_DEVICE_FAMILY = "1,2"`, iPad
  support falls out of multiplatform but the design is phone-shaped).
- **macOS 14+** — native SwiftUI Mac app (`SUPPORTS_MACCATALYST = NO`,
  `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO`, `MACOSX_DEPLOYMENT_TARGET
  = 14.0`). Opens at 520×335 — aspect-matched to the clock enclosure so
  there's no letterboxing, with minimum 360×230.

Mac Catalyst was used briefly during development as a stepping stone;
the final build is native SwiftUI on both platforms. Platform-specific
bits are isolated:

- `SettingsView.swift` has `#if os(iOS)` extensions for `EditMode`,
  `.navigationBarTitleDisplayMode`, and `.searchable` placement.
- `SettingsView.swift` applies a `#if os(macOS)` `.frame(minWidth:
  idealWidth: minHeight: idealHeight:)` so the settings sheet doesn't
  collapse to its minimum size inside the Mac modal window.
- `ContentView.swift` splits its body via `#if os(macOS)` — on macOS
  the enclosure fills the window with a black background and no gear
  button; on iOS it's centred between spacers with the gear button
  beneath.
- `DashboardEnclosureView.swift` uses `#if os(macOS)` to swap in tighter
  padding (2h/3v vs 8h/10v) and smaller row spacing (3pt vs 6pt) so the
  chassis sits tight against the rows on Mac. The `.fixedSize(vertical:)`
  is iOS-only — on macOS the enclosure expands to fill the window.
- `BttfclockApp.swift` uses `#if os(macOS)` to set `.defaultSize`,
  `.windowResizability(.contentSize)`, and a `.commands` block that
  replaces the default Settings menu with one that triggers the sheet
  via `⌘,`.

## Tech Stack

- Swift 5, SwiftUI, MVVM, `@MainActor` view models
- Pure Apple frameworks — no external dependencies
- Persistence: `UserDefaults` (city ID list, key
  `bttfclock.selectedCityIds.v1`)
- Clock tick: `Timer.publish(every: 1)` in `ClockViewModel`
- Colon step-tick: `TimelineView(.animation)` (~60Hz refresh, wall-clock
  phase)
- Tests: Swift Testing (`import Testing`, `@Test`, `#expect`) — 35 tests

## Architecture

### View hierarchy

```
BttfclockApp (defaultSize 520×335 on macOS; owns showSettings @State;
              .commands { CommandGroup(replacing: .appSettings) → ⌘, }
              forces .preferredColorScheme(.dark))
 └─ ContentView                       (owns CityStore + ClockViewModel;
                                       receives showSettings: Binding)
     ├─ TimeCircuitsView              (enclosure + three row panels)
     │   └─ DashboardEnclosureView    (dark chassis, rivets, brushed metal)
     │       └─ RowPanel ×3           (lighter grey tile per row)
     │           └─ TimeCircuitRowView
     │               ├─ display row (HStack, alignment: .bottom)
     │               │   ├─ field "MONTH" → FourteenSegmentChar ×3
     │               │   ├─ field "DAY"   → SevenSegmentDigit ×2
     │               │   ├─ field "YEAR"  → SevenSegmentDigit ×4
     │               │   ├─ AmPmIndicator  (stacked AM/PM; no caption)
     │               │   ├─ field "HOUR"  → SevenSegmentDigit ×2
     │               │   ├─ ColonSeparator (step-tick dots)
     │               │   └─ field "MIN"   → SevenSegmentDigit ×2
     │               └─ cityPlate       (grey text on black plate)
     └─ .sheet → SettingsView
         ├─ ForEach of selected cities (reorder + delete)
         ├─ NavigationLink → AddCityView (searchable curated catalog)
         └─ Reset button
```

### Row colour mapping (slot, not identity)

| Slot       | Colour | Default city |
|------------|--------|--------------|
| 0 (top)    | Red    | New York     |
| 1 (middle) | Green  | London       |
| 2 (bottom) | Amber  | Hong Kong    |

Colour is derived from the slot index via `RowColor.forIndex(_:)`.
Reordering a city therefore also changes its colour. Defaults are
time-ordered across GMT offsets so each hour rolls top-to-bottom.

### Field layout

Left-to-right: `MMM · DD · YYYY · [AM/PM] · HH · : · MM`.

- Each lettered/numeric field lives in its own recessed black window
  with a small grey-on-red caption plate above it.
- The AM/PM block has **no caption plate** — each lamp carries its own
  tiny grey-on-red "AM" / "PM" label stacked directly above it, and the
  two pairs are stacked vertically. The whole block is nudged up 5pt via
  `.offset(y: -5)` so the lamps don't overhang the digit baseline.
- Between YEAR and AM/PM there's a `dateTimeGap` (9pt) — wider than the
  regular `fieldGap` (4pt) — separating date from time.
- The colon sits between HOUR and MIN with no black window; two 5pt dots
  step-ticking in wall-clock sync.

### LED segment rendering

See `architecture.html` for a detailed visual breakdown with SVG
diagrams. Briefly:

- `SevenSegmentShape` — seven beveled bars (A–G), `UInt8` mask
- `FourteenSegmentShape` — fourteen bars and diagonals, `UInt16` mask
- Geometry constants in `SegmentShapes.swift`:
  - `thicknessRatio = 0.18` — beveled bar thickness vs shorter side
  - `italicSkew = 0.10` — x-shear as a fraction of height (right-lean)
  - `sevenSegAspect = 0.58`, `fourteenSegAspect = 0.68` — char box ratios
- Each character view stacks three layers:
  1. Ghost — all segments filled with `color.ghost`
  2. Lit core — only char-specific segments, `color.litCore` fill
  3. Glow — three `.shadow` modifiers at radii 2, 5, 11

### Colon tick

`ColonSeparator` uses `TimelineView(.animation)` so it redraws every
animation frame, but derives lit/unlit state as a **step function** from
`context.date.timeIntervalSince1970`:

```swift
static func isLit(at date: Date) -> Bool {
    let t = date.timeIntervalSince1970
    let phase = t - floor(t)
    return phase < 0.5
}
```

Lit for the first half of every wall-clock second, unlit for the
second half. No fade — the switch is instantaneous, matching the
behaviour of the real prop's multiplexed LEDs. The unlit state still
shows the row-tinted ghost circle so the tick feels subtle rather than
a flash.

Dots use the same visual treatment as the AM/PM lamps (5pt circle +
`color.lit` fill + bloom shadows + white hot-spot radial gradient).

### Dashboard enclosure

`DashboardEnclosureView` is a darker grey chassis (four-stop linear
gradient + `BrushedMetalOverlay` Canvas in `.overlay` blend mode). Four
radial-gradient `Rivet`s sit at the corners.

`RowPanel` is the lighter grey brushed-metal tile used for each row.
Thin white-opacity strip along the top edge gives a subtle bevel. The
`TimeCircuitsView` stacks three `RowPanel`s inside the enclosure with
6pt spacing (3pt on macOS for the tighter window layout).

### Platform chrome

Settings is reached differently on each platform:

- **iOS:** a "CITIES" gear button sits below the enclosure in
  `ContentView.settingsButton`, presenting the sheet.
- **macOS:** no gear button — the settings sheet is triggered from the
  app menu via a replaced `CommandGroup(replacing: .appSettings)` bound
  to `⌘,`. The menu command needs to toggle state inside the window, so
  `showSettings` lives on `BttfclockApp` as `@State` and is passed to
  `ContentView` as a `@Binding`.

The macOS window uses `.windowResizability(.contentSize)` with minimum
frame 360×230 on `ContentView`. The `.defaultSize(width: 520, height:
335)` corresponds to the natural enclosure aspect ratio (~1.55:1): row
natural aspect ≈ 5.04:1, stacked three tall with ~3pt spacing and ~3pt
outer padding on each side.

### Responsive scaling

Each `TimeCircuitRowView` scales as a single unit while preserving its
own aspect ratio — so the rows look the same on a 393pt iPhone screen
as on a 760pt Mac window:

```swift
GeometryReader { geo in
    let scale = min(geo.size.width / nat.width, geo.size.height / nat.height)
    VStack(spacing: 3) {
        displayRow.frame(width: nat.width, height: rowHeight)
        cityPlate
    }
    .fixedSize()
    .scaleEffect(scale, anchor: .center)
    .frame(width: geo.size.width, height: geo.size.height)
}
.aspectRatio(nat.width / nat.height, contentMode: .fit)
```

`naturalContentSize()` returns `intrinsicRowWidth() × (rowHeight + 3 +
cityPlateHeight)`. The whole VStack scales together, so digits **and**
city plate grow in proportion.

On iOS, `ContentView` caps the enclosure at `.frame(maxWidth: 700)` so
on iPad landscape it doesn't blow up absurdly. On macOS the cap is
removed and the enclosure fills the window — the small default window
size itself is the cap.

### Palette

Chrome colours (plate fills and plate text) live in `Models/Palette.swift`:

- `Palette.captionPlateRed` — DYMO-red behind field and AM/PM labels
- `Palette.chromeTextGrey` — off-white grey for all non-LED text
- `Palette.cityPlateBlack` — near-black behind the city name

These are deliberately shared across all three rows (same on red / green
/ amber) because on the prop they are physical painted plates, not
LEDs.

## Project structure

```
bttfclock/
├── bttfclock.xcodeproj/project.pbxproj
├── generate_icons.py                 # Pillow icon script
├── install-mac.sh                    # build Release + install in /Applications + launch
├── run_phone.sh                      # iPhone build (signed) → install → launch
├── CLAUDE.md                         # this file
├── README.md
├── architecture.html                 # visual design doc with SVG
├── tutorial.html
├── Time_Circuits_BTTF.webp           # reference photo from the film prop
├── bttfclock.png                     # hero screenshot
└── bttfclock/
    ├── App/
    │   ├── BttfclockApp.swift        # @main + macOS window sizing
    │   └── ContentView.swift         # root view + LaunchArgs enum
    ├── Models/
    │   ├── CityTimezone.swift        # struct + CityCatalog (40 cities)
    │   ├── Palette.swift             # shared chrome colours
    │   ├── RowColor.swift            # red/green/amber palette
    │   └── TimeReadout.swift         # Date × TimeZone → components
    ├── Extensions/
    │   └── SegmentMaps.swift         # char → bitmask tables
    ├── Views/
    │   ├── TimeCircuitsView.swift    # enclosure + 3 RowPanels
    │   ├── TimeCircuitRowView.swift  # one row, aspect-scaled
    │   ├── DashboardEnclosureView.swift # chassis, RowPanel, Rivet, texture
    │   ├── SettingsView.swift        # edit list + platform shims
    │   └── Components/
    │       ├── SegmentShapes.swift           # Shape types + geometry
    │       ├── SevenSegmentDigit.swift       # digit / char view composers
    │       ├── ColonSeparator.swift          # colon + AmPmIndicator
    │       └── FaceplateCaption.swift        # empty-state text helper
    ├── Services/
    │   └── CityStore.swift           # 3-city cap; UserDefaults-backed
    ├── ViewModels/
    │   └── ClockViewModel.swift      # 1s Timer; -frozendate support
    ├── Assets.xcassets/
    └── Info.plist
└── bttfclockTests/                   # PBXFileSystemSynchronizedRootGroup
    ├── CityStoreTests.swift
    ├── ClockViewModelTests.swift
    ├── ColonPulseTests.swift         # step function wall-clock sync
    ├── LaunchArgsTests.swift
    ├── SegmentMapsTests.swift
    └── TimeReadoutTests.swift
```

## Launch arguments

Applied in `ContentView.onAppear`, overriding persisted state.

| Flag          | Value                                     | Effect                                         |
|---------------|-------------------------------------------|------------------------------------------------|
| `-frozendate` | ISO8601 (e.g. `1985-10-26T01:21:00-07:00`) | Pin clock at instant; `ClockViewModel` doesn't tick. Colon keeps ticking because `TimelineView` uses the live `Date`. |
| `-cities`     | Comma-separated IDs (`london,tokyo,sydney`) | Replace selected cities on launch.           |
| `-settings`   | —                                          | Open settings sheet at launch.                |

City IDs: see `CityCatalog.all` in `Models/CityTimezone.swift` — 40
curated entries including a `hill_valley` → `America/Los_Angeles`
easter egg.

## Build & test

```bash
# iPhone simulator
xcodebuild -project bttfclock.xcodeproj -scheme bttfclock \
  -destination 'platform=iOS Simulator,name=iPhone 16' build \
  CODE_SIGNING_ALLOWED=NO

# Native macOS
xcodebuild -project bttfclock.xcodeproj -scheme bttfclock \
  -destination "platform=macOS" -allowProvisioningUpdates build

# iOS device
xcodebuild -project bttfclock.xcodeproj -scheme bttfclock \
  -destination "platform=iOS,name=Paul's iPhone 16 Pro" \
  -allowProvisioningUpdates build

# Run full test suite (iOS Simulator)
xcodebuild -project bttfclock.xcodeproj -scheme bttfclock \
  -destination 'platform=iOS Simulator,name=iPhone 16' test \
  CODE_SIGNING_ALLOWED=NO
```

### Test coverage (35 tests)

- **SegmentMapsTests** (8) — 7-seg '0'/'1'/blank; 14-seg 'O' border vs
  '0' slashed-zero; case-insensitive lookup; all month letters mapped.
- **TimeReadoutTests** (7) — classic 1985-10-26 01:21 LA fixture; 12h
  edges (midnight = 12 AM, noon = 12 PM); zero-padding; year clamping;
  month abbreviations always 3-letter uppercase.
- **CityStoreTests** (9) — default NY / London / HK; persistence
  round-trip; 3-city cap; duplicate rejection; reorder; reset;
  `availableToAdd`.
- **ClockViewModelTests** (3) — frozen-date reproducibility; unfrozen
  flag; frozen time doesn't advance.
- **ColonPulseTests** (4) — lit at second boundary; lit through first
  half-second; unlit through second half; toggles at exactly `:0.5`.
- **LaunchArgsTests** (4) — `RowColor.forIndex`; catalog integrity;
  Hill Valley easter egg.

### Deploy to iPhone

Use the bundled `run_phone.sh` for the build → install → launch flow:

```bash
./run_phone.sh                              # plain launch
./run_phone.sh -frozendate 1985-10-26T01:21:00-07:00   # forward launch-args
./run_phone.sh -cities london,tokyo,sydney  # any launch-arg works
```

It reads `APPLE_TEAM_ID` / `IPHONE_UDID` / `IPHONE_BUILD_ID` from
`~/appledev/setupenv.sh` (with the fail-loud `${VAR:?}` guard pattern), builds
for the device with `-destination "id=$IPHONE_BUILD_ID" -allowProvisioningUpdates
DEVELOPMENT_TEAM=$APPLE_TEAM_ID`, installs via `devicectl`, and launches with
any trailing arguments forwarded.

If you need to invoke `xcodebuild` manually, use this exact form — the bare
`-destination "platform=iOS,name=…"` form silently produces an *unsigned*
`.app` on this project, which then fails to install with `No code signature
found`:

```bash
xcodebuild -project bttfclock.xcodeproj -scheme bttfclock \
  -destination "id=$IPHONE_BUILD_ID" -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" build

APP=$(find ~/Library/Developer/Xcode/DerivedData/bttfclock-*/Build/Products/Debug-iphoneos/bttfclock.app -maxdepth 0)
xcrun devicectl device install app --device "$IPHONE_UDID" "$APP"
xcrun devicectl device process launch --device "$IPHONE_UDID" com.pwilliams.bttfclock
```

### Run on macOS

For day-to-day use, run the install script — it builds Release,
installs into `/Applications`, clears the autosaved window frame, and
launches:

```bash
./install-mac.sh
```

For a one-off Debug run: `open <derived-data>/Debug/bttfclock.app`,
or drag the Debug `.app` to `/Applications`.

On first Mac launch the `.defaultSize(520×335)` takes effect. SwiftUI
remembers the window frame in `UserDefaults` under a key like
`NSWindow Frame SwiftUI...`, so to reset the window after changing
defaults:

```bash
defaults delete com.pwilliams.bttfclock
rm -rf "~/Library/Saved Application State/com.pwilliams.bttfclock.savedState"
```

(`install-mac.sh` does both automatically.)

## Design decisions

- **Row colour tracks slot, not city.** Reorder = recolour. Matches the
  prop (positions are fixed red/green/amber) and makes the settings
  affordance intuitive.

- **Segments are SwiftUI Shapes, not a font.** Drawing the beveled bars
  ourselves lets us layer ghost + lit + glow precisely and guarantees
  identical output at every scale. No font file in the bundle, no
  character-fallback surprises.

- **No seconds.** The prop never had them. Keeping minute precision
  lets the pulsing colon be the "live" element.

- **Max 3 cities.** The three-row display is the whole point.

- **Curated 40-city catalog, not a full IANA picker.** IANA has ~600
  zones, most redundant.

- **Step-tick colon, not a smooth fade.** The real prop's multiplexed
  LEDs switch instantly, not fade. Dim-but-visible unlit state (via the
  ghost circle) keeps the tick subtle.

- **Per-row aspect-preserving scaling, not a global enclosure scale.**
  Earlier attempts to scale the whole `TimeCircuitsView` broke the
  individual-pane feel — the three row panels felt like one big
  billboard. Current design scales each `TimeCircuitRowView` separately
  via `.aspectRatio`, so every row keeps the screen-prop proportion
  regardless of window size.

- **Single multiplatform target, not per-platform forks.** All
  platform-specific code lives behind `#if os(iOS)` / `#if os(macOS)`
  in four files: `SettingsView.swift` (iOS edit-mode and searchable
  placement shims, plus a macOS sheet frame), `DashboardEnclosureView.swift`
  (tighter macOS padding and iOS-only `.fixedSize`), `ContentView.swift`
  (platform-split body — gear button on iOS, full-window fill on macOS),
  and `BttfclockApp.swift` (macOS default size, window resizability,
  and Settings menu command). Every other file is 100% shared.

- **macOS settings in the app menu, not a visible gear.** The user
  asked for "as little border as possible around the clock panels" on
  macOS, so the gear button is iOS-only. On macOS the settings sheet
  is reached via `⌘,` thanks to `CommandGroup(replacing: .appSettings)`.
  This required lifting `showSettings` from `ContentView`'s `@State` to
  `BttfclockApp`'s `@State` so the app-scoped `.commands` block can
  poke it — the sheet still presents from `ContentView` via the passed
  `@Binding`.

- **Window aspect matches the clock's.** Rather than letterboxing,
  the macOS `.defaultSize(520×335)` is picked so the enclosure fills
  the window at its natural aspect (~1.55:1). `ContentView` on macOS
  drops the iOS `maxWidth: 700` cap and uses `.frame(maxWidth: .infinity,
  maxHeight: .infinity)` + black background so the chassis reaches the
  edges with no chrome.

- **TimelineView for the colon, not `withAnimation`.** A SwiftUI
  animation starts whenever the view appears, so its phase would drift
  from wall-clock seconds. Computing state directly from the frame's
  `Date` keeps the tick aligned with `:00`, `:01`, `:02` … forever.

- **Per-field black windows + caption plates.** The prop has separate
  recessed windows around each numeric group with DYMO-tape labels.
  Reproducing that gives the clock a mechanical feel that a single big
  display window doesn't.

## Segment mask bugs fixed during development

Two 14-segment characters had wrong bits in the first mask table; caught
by eye on the running app. Kept here so we don't regress:

- **A** (APR / AUG / JAN / MAY): was `0x0377` (spurious H + I bits);
  corrected to `0x00F7` (A, B, C, E, F, G1, G2 only).
- **S** (SEP): was `0x018D` (unused H bit, missing G1); corrected to
  `0x00ED` (A, C, D, F, G1, G2).
- **V** was using E, F, J, M; swapped to B, F, K, M for a proper wedge
  shape (standard DSEG14 convention).

## Gotchas

- **`List` in a sheet with `.scrollContentBackground(.hidden)` +
  custom `.background(...)` collapses the row width** to ~80pt on iOS
  17/18. Use the default list background.

- **`TimeZone` lookups can fail.** `CityTimezone.timezone` falls back to
  `.gmt` when `TimeZone(identifier:)` returns nil — never force-unwrap.

- **ISO8601 parsing fragility.** `ISO8601DateFormatter` has brittle
  format options. `LaunchArgs.frozenDate()` tries three variants so any
  reasonable flag value parses.

- **Italic skew needs height.** `SegmentGeometry.skew` takes the full
  shape height, not just the current y. Factoring segment drawing into
  a helper that doesn't know char height → inconsistent skew.

- **`.frame(height:, alignment:)` doesn't clip overflow.** Overflowing
  content still draws; alignment only positions the content within the
  frame. The AM/PM block uses a fixed frame + explicit `.offset(y: -5)`
  to nudge without clipping.

- **SwiftUI window frame autosaves.** macOS stores window position/size
  in `UserDefaults` under `NSWindow Frame SwiftUI...`. Changing
  `.defaultSize` won't affect an already-launched user's window; they
  need to delete the entry or the app's saved state.
