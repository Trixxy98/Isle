# Isle

A Dynamic Island for the MacBook notch, built natively in SwiftUI. Isle turns the
empty space around the camera housing into a Now Playing display for Apple Music
and Spotify: artwork and a colour-matched equalizer while collapsed, full
transport controls when you hover.

macOS has no Dynamic Island API. Isle fakes one convincingly with a borderless,
transparent `NSPanel` pinned to the notch, drawing everything itself.

## Features

- **Collapsed island** flush with the menu bar: album artwork plus an animated
  equalizer, sitting in the slivers either side of the camera housing.
- **Hover to expand** into a card with title, artist, a draggable seek bar,
  elapsed/remaining time, and play / pause / skip.
- **Colours from the artwork** — each equalizer bar samples a vivid colour out of
  the current album cover, so the island shifts with whatever is playing.
- **Apple Music and Spotify**, picked automatically based on which one is
  actually playing.
- **Menu bar only** — no Dock icon, no windows. Launch at login is a toggle.
- **Works without a notch** too: the island falls back to a centred pill at the
  top of the screen.

## Requirements

- macOS 14 or later (developed and tested on macOS 27, MacBook Air M4)
- Swift 6 toolchain — either Xcode 16+ or the Command Line Tools
  (`xcode-select --install`)

## Build

```bash
git clone https://github.com/<your-user>/Isle.git
cd Isle
chmod +x Scripts/bundle.sh
./Scripts/bundle.sh
open dist/Isle.app
```

`Scripts/bundle.sh` builds the release binary with SwiftPM, assembles
`dist/Isle.app` around it, and ad-hoc signs the bundle. To keep Isle around, drag
`dist/Isle.app` into `/Applications` and enable **Launch at Login** from the menu
bar item.

After changing any source file, rebuild and relaunch:

```bash
pkill -x Isle
./Scripts/bundle.sh
open dist/Isle.app
```

## Usage

Play something in Apple Music or Spotify and the island appears under the notch.
Hover it to expand, move away to collapse. With nothing playing, the island
stays hidden behind the camera housing.

On first use macOS asks for permission to control Music and Spotify. Isle needs
this to read track information; without it the island stays empty. You can
change it later in **System Settings → Privacy & Security → Automation**.

If you already run another notch app (NotchBox, NotchNook, boring.notch), quit it
first so the two overlays do not stack.

## How it works

**Finding the notch.** The cutout is never hardcoded.
[`NotchGeometry`](Sources/Isle/Island/NotchGeometry.swift) reads
`NSScreen.safeAreaInsets` along with `auxiliaryTopLeftArea` and
`auxiliaryTopRightArea` — the two menu bar slivers beside the camera — and
derives the notch width from the gap between them. Its height comes from the
real menu bar height (`frame.maxY - visibleFrame.maxY`), which is a touch taller
than the safe area inset, so the collapsed island lines up with the menu bar
exactly.

**The window.** [`IslandPanel`](Sources/Isle/Island/IslandPanel.swift) is a
borderless, non-activating `NSPanel` above the status bar level that joins all
Spaces and never takes focus. It ignores mouse events until the pointer is
actually over the island, so it never steals clicks from the menu bar.

**Now Playing.** Apple restricted the private MediaRemote framework to
Apple-signed processes in macOS 15.4, so system-wide Now Playing is off the
table without a helper binary. Isle instead talks to Music and Spotify through
their own AppleScript interfaces, which are supported and need no private API.
Playback state is polled about once a second on a background queue.

**Artwork colours.** [`ArtworkPalette`](Sources/Isle/Features/NowPlaying/ArtworkPalette.swift)
squashes the cover into a single row of pixels, keeps the most saturated sample
from each horizontal slice, and forces a minimum saturation and brightness so
dark covers still read against the black island. This runs once per track
change, not per frame.

## Project structure

```
Sources/Isle/
  IsleApp.swift              App entry, panel hosting, hover tracking
  AppModel.swift             Shared observable state
  Island/
    NotchGeometry.swift      Notch and menu bar measurement
    IslandPanel.swift        NSPanel + hosting view hit testing
    IslandController.swift   Idle / compact / expanded sizing and springs
    IslandView.swift         Island shape and layout
  Features/NowPlaying/
    NowPlayingViews.swift    Collapsed island, equalizer, artwork
    ExpandedNowPlaying.swift Expanded card, seek bar, transport
    ArtworkPalette.swift     Colour extraction from album art
  Services/
    NowPlayingService.swift  Music/Spotify polling and commands
  Settings/
    AppSettings.swift        Launch at login
    SettingsMenu.swift       Menu bar menu
Scripts/bundle.sh            Build + .app packaging
Resources/Info.plist         LSUIElement, bundle metadata
```

## Limitations

- Not App Store eligible: it relies on Apple Events automation and a
  status-bar-level overlay.
- Only Apple Music and Spotify. Browser audio and YouTube are not detected,
  since that needs MediaRemote.
- Isle does not read other apps' notifications — macOS provides no API for
  that. It is a Now Playing island, not a notification centre.
- The middle of the island at menu bar height has no pixels behind it; that area
  is the physical camera cutout. Content is deliberately placed in the slivers
  beside it, or below the notch when expanded.

## Troubleshooting

**Island never appears.** Check Isle is running (`pgrep -x Isle`) and that Music
or Spotify is actually playing, not paused.

**Island is empty while music plays.** Automation permission was likely denied.
Re-enable it under System Settings → Privacy & Security → Automation, then
relaunch Isle.

**Two islands on screen.** Another notch app is running. Quit it.

## License

No license file yet. Add one before publishing if you want others to reuse the
code.
