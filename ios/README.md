# Aseprite for iPad

Unofficial iPadOS port of Aseprite. The app runs the regular desktop
UI on top of a UIKit backend for [laf](https://github.com/EYamanS/laf/tree/ios)
(`laf/os/ios`), with touch, Apple Pencil, hardware keyboard and
trackpad support.

> Aseprite is distributed under the [Aseprite EULA](../EULA.txt). You
> can compile it for your own personal use, but you cannot
> redistribute the compiled app (no App Store/TestFlight/IPA sharing).

## Requirements

* A Mac with Xcode 16+ (tested with Xcode 26)
* `brew install cmake ninja`
* An iPad with iPadOS 15+ and Developer Mode enabled
  (Settings > Privacy & Security > Developer Mode)
* An Apple ID added in Xcode > Settings > Accounts (a free personal
  team works, the app must be re-installed every 7 days)

## Build

```sh
git clone --recursive -b ios https://github.com/EYamanS/aseprite.git
cd aseprite

# 1. Compile Skia for iOS and the host code generator (~5 minutes)
ios/build.sh deps

# 2. Generate the Xcode project (TEAM_ID from Xcode > Settings >
#    Accounts, bundle id must be unique for your team)
ios/build.sh xcode YOUR_TEAM_ID com.yourname.aseprite
```

Open `../build-ios-xcode/aseprite.xcodeproj`, select the **aseprite**
scheme and your iPad as destination, and press **Run**.

The first launch may fail with "Untrusted Developer": on the iPad go
to Settings > General > VPN & Device Management and trust your
developer certificate.

## Controls

| Input | Action |
|---|---|
| Apple Pencil | Left mouse button with pressure |
| Pencil double-tap | Toggle Eraser / previous tool |
| Pencil Pro squeeze | Switch foreground/background colors |
| One finger on the canvas | Scroll (or draw, if **Finger Draw** is enabled) |
| One finger on the UI | Click / drag (buttons, menus, layers, palette) |
| Long press (one finger) | Right click (context menus) |
| Two fingers drag | Scroll / pan the canvas |
| Pinch | Zoom |
| Two-finger tap | Undo |
| Three-finger tap | Redo |
| Trackpad / mouse | Pointer, right click, scroll and pinch |
| Hardware keyboard | All the regular keyboard shortcuts (Cmd+Z, B, E, etc.) |

The bar at the top of the screen has:

* **Finger Draw**: when it's off (default) only the Apple Pencil draws
  and one finger scrolls the canvas; turn it on to draw with a finger
* Sticky modifier keys (Shift, Ctrl, Alt, Cmd, Space)
* Esc, Del, Enter, Undo, Redo, and a button to show the software
  keyboard

Screen scaling defaults to 300%; you can change it in
Edit > Preferences > General.

## Files

Files are stored in the app's Documents folder, which is visible in
the Files app (On My iPad > Aseprite). You can also open
`.aseprite`/`.ase`/`.png`/`.gif` files from the Files app with "Share >
Aseprite" or "Open with".

## What's ported

* `laf/os/ios`: UIKit app/scene lifecycle, event queue (nested
  CFRunLoop), window/view, touch/pencil/keyboard/pointer input,
  on-screen modifier toolbar
* `laf/os/skia/skia_window_ios.mm`: raster Skia surface presented
  through a CALayer
* `laf/clip/clip_ios.mm`: clipboard (text, images, custom formats)
  using UIPasteboard
* Skia is compiled raster-only (no GPU) for iOS, see
  `ios/skia-ios.patch` for a small fix in Skia's iOS file handling
