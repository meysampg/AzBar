# Screenshots

## Required sizes

| Device | Size (portrait, px) | Status |
|---|---|---|
| iPhone 6.9" | 1320 × 2868 | Required |
| iPhone 6.5" | 1242 × 2688 or 1284 × 2778 | Optional (scaled from 6.9" if absent) |
| iPad 13" | 2064 × 2752 | Required, because the app supports iPad |

The iPhone build is portrait only; capture iPad in portrait too.

## Shot list (in this order)

1. **Reader** in Nastaliq with the player bar visible. Hafez, «غزل شمارهٔ ۱».
2. **Learn** at a cloze step: some words hidden, one revealed.
3. **Review** with the rating bar showing «دوباره / سخت / خوب / آسان» and the next intervals.
4. **Today** with the streak and due count, and a couple of poems in progress.
5. **Library** (the Hafez list or a search result for a Persian phrase).
6. **Settings** with the font preview (Naskh, Nastaliq or Vazirmatn).
7. **Fal** result, last. Take it in dark mode (see below).

Appearance: shots 1 to 6 in light mode, plus one dark-mode shot (use the Fal result, or swap in the Reader).

Use real, realistic data: a few poems memorized, a streak of several days. Keep the status bar clean (full battery, 9:41 as the simulator provides).

## Capture

Simulator:

```sh
xcrun simctl boot "iPhone 16 Pro Max"      # any 6.9" device
xcrun simctl ui booted appearance light    # or dark
xcrun simctl io booted screenshot docs/screenshots/01-reader.png
```

Use the iPad Pro 13-inch (M4) simulator for the iPad set. Check the pixel size with `sips -g pixelWidth -g pixelHeight <file>`; it must match the table above exactly.

Repo and README screenshots: `Tools/capture_screenshots.sh` builds the DEBUG app, installs it on the connected iPhone and captures every screen with `devicectl`, using the demo mode in `AzBar/App/DebugLaunch.swift` (`-AzBarDemo YES -AzBarScreen <name>`: in-memory seeded data, the real store is never touched). The output is downscaled to 1000 px in `docs/screenshots/`; these are not the App Store sizes above.

On a device: press side button and volume-up together, then AirDrop the files to the Mac.

## Where files go

Store the finals in `docs/screenshots/` (also used by the README), named `NN-name.png` with a prefix per device: `iphone-69/`, `ipad-13/`. Upload in the order above in App Store Connect.
