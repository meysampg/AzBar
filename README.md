<p align="center"><img src="AzBar/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="128" alt="AzBar app icon"></p>

# ازبر · AzBar

[![CI](https://github.com/meysampg/AzBar/actions/workflows/ci.yml/badge.svg)](https://github.com/meysampg/AzBar/actions/workflows/ci.yml)

ازبر برنامه‌ای برای حفظ کردن شعر فارسی است، با دیوان حافظ. بیت‌به‌بیت می‌خوانید، می‌شنوید، جای خالی‌ها را پر می‌کنید و با مرورِ فاصله‌دار شعر را برای همیشه از بر می‌کنید.

AzBar («az bar», from memory) is a free, open-source iOS app for memorizing Persian poetry, starting with the Divan of Hafez. You read each couplet, listen to a recitation, fill in progressively more blanks, and then review it on a spaced-repetition schedule. The whole interface is Persian and right-to-left.

> Screenshots will be added to `docs/screenshots/`.

## Features

- The full Divan of Hafez, 692 poems, bundled for offline use; Saadi and Khayyam load online from Ganjoor
- Couplet meanings, shown or hidden as you like
- Recitations synced to the text, with lock-screen playback
- A guided Learn flow: read, listen, cloze levels, first letters, recall
- FSRS-5 spaced-repetition reviews with a daily streak and optional reminders
- Fal-e Hafez: open the Divan to a random ghazal
- Diacritic-insensitive search across bundled poems
- Naskh, Nastaliq and Vazirmatn fonts
- Full RTL layout, Dynamic Type, and Liquid Glass on iOS 26

## Memorization method

Each beyt goes through the same sequence in the Learn flow:

1. **Read and listen** to the couplet and its meaning.
2. **Cloze levels**: 30%, then 60%, then 100% of the words are hidden. Common stopwords (و، به، از...) are hidden last, so the meaningful words are tested first. The hiding order is seeded per couplet, so it is stable across sessions.
3. **First letters**: every word is replaced by a hint of its first letter.
4. **Recall the second mesra** from the first, and, when there is a previous beyt, **recall the next beyt** to chain the poem together.
5. **Rate** how well you remembered: Again, Hard, Good or Easy.

Every couplet is then scheduled individually with [FSRS-5](https://github.com/open-spaced-repetition/fsrs4anki/wiki/The-Algorithm). Reviews show you the prompt, then the answer, then the same four ratings. In Settings you choose the target retention (85%, 90% or 95%), how many new couplets to learn per session, and the daily review limit.

## Architecture

```
AzBar (iOS app)                      SwiftUI, SwiftData, AVPlayer
  App · Features (Today, Library, Reader, Learn, Review, Fal, Settings)
  DesignSystem · Persistence · Audio · Notifications
        │ import
        ▼
AzBarKit (local Swift package, Foundation only)
  Models · Text · Content (bundled + Ganjoor sources, search, sync)
  Memorization (FSRS-5, cloze, Learn and Review engines)
```

All pure logic lives in the package and is tested on the host with `swift test`. The details, data schemas and engine formulas are in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Requirements and build

- Xcode 26 or newer; the app targets iOS 26.
- Run the package tests: `swift test --package-path Packages/AzBarKit`
- Build for the simulator:

  ```sh
  xcodebuild -project AzBar.xcodeproj -scheme AzBar -configuration Debug \
    -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
  ```

- To run on a device, open `AzBar.xcodeproj`, then set your own Team and a unique bundle identifier under Signing & Capabilities. Do not commit those changes.

## Adding a poet

1. Add an entry to `AzBar/Resources/Content/poets-catalog.json` with the poet's Ganjoor id and root category id. With `"bundledPack": null` the poet is browsed online.
2. To bundle a poet for offline use, build a content pack and point the catalog entry at it:

   ```sh
   python3 -I Tools/fetch_ganjoor.py --poet-id <id> --slug <slug>
   ```

   This writes `AzBar/Resources/Content/pack-<slug>.json`; set `"bundledPack": "pack-<slug>"`. Useful flags: `--out`, `--cache`, `--delay`, `--only-cats 24,25` and `--no-summaries` (leave out the Ganjoor meanings). Raw API responses are cached in `Tools/.cache/`.
3. `Tools/cache_ganjoor_raw.py <poet-id> <cache-dir>` pre-fills that cache, and `Tools/fetch_fonts.sh` re-downloads the bundled fonts.

Search covers bundled poets only.

## Credits and licences

- The source code is released under the [MIT licence](LICENSE).
- Fonts: [Vazirmatn](https://github.com/rastikerdar/vazirmatn) by Saber Rastikerdar, and Noto Naskh Arabic and Noto Nastaliq Urdu by Google. All are under the SIL Open Font License 1.1; the licence texts are in `AzBar/Resources/Fonts/*-OFL.txt`.
- Poem texts come from [Ganjoor](https://ganjoor.net); the poems themselves are classical, public-domain poetry.
- Couplet meanings, summaries, recitations and sync data come from Ganjoor and its contributors and reciters. They are **not** covered by the MIT licence, remain the property of their rights holders, and are included or streamed with attribution.

## More

- [Privacy policy](PRIVACY.md)
- [Contributing](CONTRIBUTING.md)
- [Releasing](docs/RELEASING.md)
- [App Store materials](docs/appstore/)
