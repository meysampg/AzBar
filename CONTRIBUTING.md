# Contributing to AzBar

Thanks for helping. Bugs and ideas are welcome as [issues](https://github.com/meysampg/AzBar/issues).

Before opening a pull request:

1. Run the kit tests: `swift test --package-path Packages/AzBarKit`
2. Make sure the app builds:
   `xcodebuild -project AzBar.xcodeproj -scheme AzBar -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO -quiet build-for-testing`

Conventions:

- Swift 6 with strict concurrency; see the concurrency rules in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
- Persian UI strings are inline literals (`Text("مرور")`). Poem text goes through `Text(verbatim:)` and never through a literal key. Numbers are shown in Persian digits via `.fa`, never interpolated raw.
- Pure logic belongs in `Packages/AzBarKit` (Foundation only) with tests; the app target holds UI and persistence.
- Do not commit changes to the signing team or bundle identifier. Set your own locally when running on a device.
- Poem content changes only through `Tools/fetch_ganjoor.py`; do not edit `pack-hafez.json` by hand.
