# Tickday

Tickday is a native, offline macOS 14+ personal dashboard written in SwiftUI. It manages countdown events and dated or recurring tasks, stores them in a shared SwiftData database, and includes an interactive WidgetKit desktop widget.

## Features

**App**

- Today, Countdowns, Tasks, and Settings sections in a sidebar layout.
- Countdowns: create, edit, duplicate, reorder, search, and sort (nearest, farthest, created, custom).
- Tasks: dated and recurring tasks with per-day completion. The toolbar hosts day navigation, a completion filter, a hide-completed toggle, and a collapsed search button that expands in place of the day controls.
- Settings: past-countdown behavior, hide-completed default, the widget's first page, and a right-to-left layout toggle that applies to the widget and to the Countdowns and Tasks pages.
- Deep links (`tickday://today`, `countdowns`, `tasks`, `countdown?id=UUID`, `task?id=UUID`, `new-countdown`, `new-task`).

**Widget (small, medium, large)**

- Transparent container — content renders directly over the wallpaper with no card or material. macOS may still apply its own tint to inactive desktop widgets (System Settings → Desktop & Dock → Widget style).
- Two pages, countdowns and tasks, switched with subtle chevrons. The page order is configurable in Settings and never flips in right-to-left mode.
- Countdown values are numeric-only calendar-day counts (`2`, not "2 days"; `0` today; negative when passed). VoiceOver still announces the full meaning.
- The nearest upcoming countdown renders large and bold; the rest are compact rows with numbers on a shared trailing edge.
- Task checkboxes toggle in place; clicking anywhere else opens the app on the matching page.

## Data storage

All data lives in one SwiftData (SQLite) store inside the Tickday App Group container — the only channel a sandboxed widget can share with its app. Users never configure anything: macOS creates the container automatically when the app is signed correctly. Before distributing, replace the `com.example` identifiers in `Tickday/Utilities/AppConstants.swift`, both `.entitlements` files, and the target build settings with your own bundle IDs and a Team ID–prefixed app group.

## Building and testing

```sh
xcodebuild -project Tickday.xcodeproj -scheme Tickday -configuration Debug build
xcodebuild -project Tickday.xcodeproj -scheme Tickday -destination 'platform=macOS' test
```

## Packaging a release

```sh
xcodebuild -project Tickday.xcodeproj -scheme Tickday -configuration Release \
  SYMROOT="$PWD/dist/build" build
ditto -c -k --keepParent dist/build/Release/Tickday.app dist/Tickday-1.0.zip
```
