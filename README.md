# Time Circuits

An **iPhone + Mac** clock that shows three world cities on a faithful
recreation of the Back to the Future DeLorean **Time Circuits** display
— red, green, and amber LED rows on three grey brushed-metal tiles,
with grey-on-red DYMO-tape caption plates, stacked AM/PM indicators,
and a colon that step-ticks in sync with wall-clock seconds.

![Screenshot](https://pcwilliams.design/dev/bttfclock/bttfclock.png)

## Features

- Three colour-coded rows (red / green / amber) rendered with
  hand-drawn 7-segment and 14-segment LED shapes — no fonts, no
  bitmaps, pure SwiftUI `Path`s.
- Each row shows `MMM · DD · YYYY · AM/PM · HH:MM` for one city.
- Grey-on-red caption plates ("MONTH", "DAY", "YEAR", "HOUR", "MIN")
  sit above each black recessed segment window, like the DYMO-tape
  labels on the screen-used prop.
- Slim AM/PM indicator: two tiny grey-on-red plates stacked vertically,
  each above a small row-coloured lamp.
- Colon between HOUR and MIN **step-ticks in lock-step with wall-clock
  seconds** — lit for the first half of each second, unlit for the
  second half, switching instantly rather than fading. Stays
  synchronised with `:00`, `:01`, `:02`… forever regardless of when
  the app launched.
- Each row sits on its own lighter-grey brushed-metal tile with a
  subtle bevel; the whole thing mounts onto a darker chassis with
  rivets at the corners.
- **Scales with the window.** Each row uses `.aspectRatio` +
  `GeometryReader` + `.scaleEffect` to preserve its proportions
  whether it's rendering on a 393pt iPhone screen or a native Mac
  window. On macOS the window opens at an aspect ratio that matches
  the clock's natural proportions, so there's no letterboxing.
- **Chromeless Mac layout.** On macOS the chassis fills the window
  edge to edge — no gear button. Settings is reached from the app menu
  (⌘,). On iOS the gear button sits below the display.
- Settings pane with a curated catalog of 40 world cities,
  drag-to-reorder, swipe-to-delete, and a Reset button.
- Persisted across launches via `UserDefaults`.
- Zero external dependencies — iOS 17+, macOS 14+, pure SwiftUI.

## Default cities

The app ships with **New York → London → Hong Kong** — deliberately
time-ordered across GMT offsets so each hour rolls down the display
from top (red) to bottom (amber).

You can add, remove, or reorder via the settings gear. The colour of a
row is tied to its position, not its city — move London to the top slot
and London becomes red.

## Platforms

- **iOS 17.0+** — iPhone portrait
- **macOS 14+** — native SwiftUI Mac app (Mac Catalyst is *not* used;
  the same binary is a real Mac app with a proper titlebar and window
  chrome). Opens at 520×335 by default — the window's aspect ratio
  matches the clock's natural proportions so there's minimal border
  around the panels. Minimum size 360×230.
- Xcode 16+ to build.

The iOS and macOS builds share the same source; platform-specific bits
are isolated behind `#if` gates in four files — the rest of the source
compiles unchanged on both. See CLAUDE.md for the full list.

## Setup

```bash
git clone <this-repo>
cd bttfclock

# Quickest way to get it on your Mac: build Release, install to
# /Applications, launch. Clears the SwiftUI-autosaved window frame so
# the new build opens at its current .defaultSize.
./install-mac.sh

# Build for iPhone (simulator-safe, no signing)
xcodebuild -project bttfclock.xcodeproj -scheme bttfclock \
  -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO

# Build for native macOS (Debug)
xcodebuild -project bttfclock.xcodeproj -scheme bttfclock \
  -destination "platform=macOS" -allowProvisioningUpdates build
```

Open `bttfclock.xcodeproj` in Xcode to run on a real iPhone — set your
own development team in Signing & Capabilities. In Xcode's scheme
destination selector, pick **My Mac** to run the native Mac build, or
use `install-mac.sh` to drop a Release build into `/Applications`.

On macOS, open settings with **⌘,** (there's no on-screen gear button —
the clock fills the window).

## How it works

1. `CityStore` loads up to 3 `CityTimezone` structs from `UserDefaults`.
   First launch seeds it with New York / London / Hong Kong.
2. `ClockViewModel` publishes a `now: Date` every second via
   `Timer.publish(every: 1)` — or holds a fixed instant if `-frozendate`
   was passed on launch.
3. Each tick, `ContentView` asks the view model for three
   `TimeReadout`s (one per city's `TimeZone`) and passes them into
   `TimeCircuitsView`.
4. `TimeCircuitRowView` lays out the `MONTH·DAY·YEAR·AM/PM·HH:MM`
   fields. Each field has its own black recessed window with a small
   grey-on-red caption plate above it. The AM/PM block is captionless
   but its two lamps each carry their own tiny grey-on-red label.
5. Each segment view stacks a dim "ghost" `Shape` beneath a lit
   `Shape` with three `.shadow(...)` modifiers for the LED bloom.
6. The colon is a `TimelineView(.animation)` that derives its lit/unlit
   state from `context.date.timeIntervalSince1970`'s sub-second phase
   — lit when phase < 0.5, unlit otherwise. Toggles exactly on the
   half-second mark, in perfect sync with real time.

See [architecture.html](https://pcwilliams.design/dev/bttfclock/architecture.html) for an in-depth visual
design doc with SVG diagrams of the LED segment geometry.

## Launch arguments

| Flag          | Example                                   | Effect                                             |
|---------------|-------------------------------------------|----------------------------------------------------|
| `-frozendate` | `-frozendate 1985-10-26T01:21:00-07:00`   | Pin the clock to a specific instant.               |
| `-cities`     | `-cities london,tokyo,sydney`             | Override selected cities (persisted selection).    |
| `-settings`   | `-settings`                               | Open the settings sheet at launch.                 |

Valid city IDs are in `CityCatalog.all` in `Models/CityTimezone.swift`
— 40 entries spanning every continent, plus a `hill_valley` easter egg.

## Testing

35 Swift Testing cases cover segment maps, timezone conversion,
`CityStore` persistence, clock-model freezing, colon step-tick timing,
and launch-argument plumbing.

```bash
xcodebuild -project bttfclock.xcodeproj -scheme bttfclock \
  -destination 'platform=iOS Simulator,name=iPhone 16' test \
  CODE_SIGNING_ALLOWED=NO
```

## Tech stack

- Swift 5, SwiftUI, MVVM
- `@MainActor` view models, `@ObservableObject`
- `TimelineView(.animation)` for the wall-clock-synced colon tick
- `GeometryReader + .aspectRatio + .scaleEffect` for responsive
  per-row scaling
- Single multiplatform target — native iOS **and** native macOS from
  the same binary
- Zero external dependencies (SwiftUI + Foundation only)

## More

- [architecture.html](https://pcwilliams.design/dev/bttfclock/architecture.html) — detailed design document with
  inline SVG illustrations of the LED segment geometry, bitmask
  composition, ghost/lit/glow layering, italic skew, and responsive
  scaling.
- [tutorial.html](https://pcwilliams.design/dev/bttfclock/tutorial.html) — the narrative of how this app was
  built (and iterated) through Claude Code conversation.
- [CLAUDE.md](CLAUDE.md) — deep technical reference.
