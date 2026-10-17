# AzBar architecture

AzBar («ازبر») is an iOS 26 app for memorizing Persian poetry. This document describes how it is built: the module layout, data schemas, the memorization engine, the app-layer contracts, the screens, the Ganjoor API behaviour the code depends on, and how to test.

## 1. Architecture

```
┌────────────────────────── AzBar (iOS app target) ───────────────────────────┐
│ App/ (AzBarApp, AppModel, RootView, AppSettings, env keys)                  │
│ Features/ Today │ Library │ Reader │ Learn │ Review │ Fal │ Settings        │
│      │ use                                                                  │
│ DesignSystem/ (fonts, typography, PersianNumber, CoupletView, FlowLayout,   │
│               ClozeMesraView, PlayerBar, RatingBar, HoldToConfirmButton)    │
│ Persistence/ (SwiftData SchemaV1 + ProgressStore @MainActor)                │
│ Audio/ (AudioPlayerService @MainActor, AVPlayer)                            │
│ Notifications/ (ReminderScheduler @MainActor)                               │
│ Resources/ (fonts, poets-catalog.json, pack-hafez.json, Assets, xcstrings)  │
└───────────────┬─────────────────────────────────────────────────────────────┘
                │ import AzBarKit (re-exported via @_exported)
┌───────────────▼────────── Packages/AzBarKit (SPM, Foundation only) ──────────┐
│ Models/  Poet, PoemCategory, Poem, Couplet, Verse, Recitation, CoupletKey,   │
│          PoetCatalog, ContentPack          (all Codable+Sendable structs)    │
│ Text/    PersianText (normalize, strip diacritics), PersianTokenizer, stops  │
│ Content/ PoemSource protocol, BundledPoemSource(actor),                      │
│          GanjoorRemoteSource(actor)+DTOs+Mapper+DiskCache,                   │
│          ContentRepository(final Sendable), SearchIndex(actor), RecitationSync│
│ Memorization/ FSRS types+FSRSScheduler, SeededRandom, ClozeEngine,           │
│          LearnSessionEngine, ReviewSessionEngine, PoemProgress               │
│ Tests/AzBarKitTests (Swift Testing, macOS host)                              │
└──────────────────────────────────────────────────────────────────────────────┘
Tools/fetch_ganjoor.py → AzBar/Resources/Content/pack-hafez.json
Tools/fetch_fonts.sh   → AzBar/Resources/Fonts/*.ttf
```

**Data flow**
- Content: `ContentRepository` uses `PoetCatalog` to pick the source for a poet (bundled pack URL or remote). It returns `Poem` values. The UI gets it through `@Environment(\.contentRepository)`.
- Progress: SwiftData `CoupletCard` records are keyed by `"poemId:coupletIndex"`. They are only read and written through `ProgressStore`. Engines receive plain `FSRSCard` value snapshots.
- Content and progress are fully separate. Ganjoor poem ids are globally unique, so adding a poet never collides.

**Concurrency rules (Swift 6, strict)**
- `SWIFT_VERSION = 6.0`. Do **not** set `SWIFT_DEFAULT_ACTOR_ISOLATION` or `SWIFT_APPROACHABLE_CONCURRENCY`. The default stays nonisolated so that Codable conformances and engines remain non-MainActor.
- Every `@Observable` class is `@MainActor final class`.
- Every domain or engine type is a `Sendable` struct. Sources are `actor`s. `ContentRepository` is a `final class: Sendable` with only `let` properties.
- SwiftData models are only touched on `@MainActor` (`ProgressStore` uses `container.mainContext`). Model objects never cross actors.
- AVPlayer and notification callbacks use `queue: .main` plus `MainActor.assumeIsolated { }`.
- No `static var`. Use `static let` only.

**Strings**
- Persian UI strings are inline literals (`Text("مرور")` is a `LocalizedStringKey`): no key indirection, the code reads as the UI reads.
- `developmentRegion = fa`, `knownRegions = (fa, Base)`, and `CFBundleLocalizations = [fa]`.
- `Localizable.xcstrings` has `sourceLanguage: "fa"`; `SWIFT_EMIT_LOC_STRINGS = YES` lets Xcode extract strings when a second language is added.
- Poem text always goes through `Text(verbatim:)` or a `String` variable, never a literal key.

**RTL and locale**
- Because the only localization is `fa`, UIKit chrome (navigation bar back chevron, swipe-back) is RTL.
- At the root also apply:
  - `.environment(\.layoutDirection, .rightToLeft)`
  - `.environment(\.locale, Locale(identifier: "fa_IR"))`
  - `.environment(\.calendar, Calendar(identifier: .persian))`
- Never interpolate a raw `Int` or `Double` into UI text. Always use `n.fa` from `PersianNumber`.


## 2. Repository layout

```
Config/Info.plist                 merged with the generated plist
AzBar.xcodeproj                   objectVersion 77, synchronized folder groups, local package reference
Tools/                            fetch_ganjoor.py, cache_ganjoor_raw.py, fetch_fonts.sh
Packages/AzBarKit/                Package.swift, Sources/AzBarKit/{Models,Text,Content,Memorization}, Tests/AzBarKitTests (+ Fixtures)
AzBar/App/                        AzBarApp, Exports, AppModel, AppSettings, AppTab, RootView, EnvironmentKeys
AzBar/Persistence/                SchemaV1, ProgressStore
AzBar/Notifications/              ReminderScheduler
AzBar/Audio/                      AudioPlayerService, RecitationPicker
AzBar/DesignSystem/               AppFonts, UIKitAppearance, PersianNumber, IntervalFormatter, Theme,
                                  Components/{MesraText, CoupletView, FlowLayout, ClozeMesraView, RatingBar,
                                  PlayerBar, HoldToConfirmButton, ProgressRing}, Preview/PreviewFixtures
AzBar/Features/                   Today, Library, Reader, Learn, Review, Fal, Settings
AzBar/Resources/                  Assets.xcassets, Fonts, Content/{poets-catalog.json, pack-hafez.json}, Localizable.xcstrings
AzBarTests/                       ProgressStoreTests, AppSettingsTests, PersianNumberTests, BundledContentSmokeTests
```

**Filename uniqueness.** Every filename inside `AzBar/` must be unique: synchronized groups flatten resources into the bundle root, and Swift files with the same name in different folders fail with "filename used twice". Licence files are therefore named `Vazirmatn-OFL.txt`, not `OFL.txt`.

### Package.swift

```swift
// swift-tools-version: 6.2
import PackageDescription
let package = Package(
  name: "AzBarKit",
  platforms: [.iOS(.v26), .macOS(.v15)],
  products: [.library(name: "AzBarKit", targets: ["AzBarKit"])],
  targets: [
    .target(name: "AzBarKit"),
    .testTarget(name: "AzBarKitTests", dependencies: ["AzBarKit"], resources: [.copy("Fixtures")])
  ]
)
```

- Every kit type, property, init or func used by the app must be `public`.
- Structs need an explicit `public init`.
- The kit imports Foundation only. No SwiftUI, AVFoundation or SwiftData.

## 3. Data schemas

### 3a. Kit domain models (all `public struct …: Codable, Sendable, Hashable`)

```swift
public typealias PoetID = Int; public typealias CategoryID = Int; public typealias PoemID = Int
public struct Poet: Identifiable { id, name /*"حافظ"*/, fullName /*"حافظ شیرازی"*/, slug, rootCategoryId: Int, description: String?, birthYearHijri: Int?, deathYearHijri: Int? }
public struct CategoryRef: Identifiable { id: Int; title: String }
public struct PoemSummary: Identifiable { id, categoryId: Int; title, urlSlug: String; excerpt: String?; coupletCount: Int? }
public struct PoemCategory: Identifiable { id, poetId: Int; title, slug: String; parentId: Int?; children: [CategoryRef]; poems: [PoemSummary] }
public struct Verse: Identifiable { id /*ganjoor verse id*/, order /*vOrder*/, position: Int; text: String }
public enum CoupletKind: String, Codable, Sendable { case beyt, single, paragraph }
public struct Couplet: Identifiable { index: Int; kind: CoupletKind; verses: [Verse]; summary: String?
  var id: Int { index }; var firstMesra: String; var secondMesra: String?; var isMemorizable: Bool { kind != .paragraph && index >= 0 } }
public struct Recitation: Identifiable { id: Int; artist: String; mp3Url: URL; syncUrl: URL?; order: Int; type: Int; synced: Bool }
public struct SyncPoint: Sendable, Hashable { verseOffset: Int /*0-based into orderedVerses*/; milliseconds: Int }
public struct Poem: Identifiable { id, poetId, categoryId: Int; title, fullTitle, urlSlug, fullUrl: String; summary: String?; couplets: [Couplet]; recitations: [Recitation]
  var orderedVerses: [Verse]; var memorizableCouplets: [Couplet]
  func couplet(at index: Int) -> Couplet?; func previousMemorizable(before index: Int) -> Couplet?
  func coupletIndex(forVerseOffset: Int) -> Int?; var plainText: String; var ganjoorURL: URL /* https://ganjoor.net + fullUrl */ }
public struct CoupletKey: Hashable, Codable, Sendable { poemId, coupletIndex: Int; var stringValue: String /*"2130:0"*/; init?(string:) }
public struct PoetCatalogEntry: Identifiable { id, slug, name, fullName, rootCategoryId; bundledPack: String?; falCategoryId: Int?; birthYearHijri: Int?; deathYearHijri: Int?; sortOrder: Int; isEnabled: Bool }
public struct PoetCatalog { schemaVersion: Int; poets: [PoetCatalogEntry]; static func load(from: URL) throws -> PoetCatalog; var enabledPoets: [PoetCatalogEntry] /*sorted*/ ; func entry(_ id: PoetID) -> PoetCatalogEntry? }
public struct ContentPack { schemaVersion: Int; generatedAt: String; source: String; poet: Poet; categories: [PoemCategory]; poems: [Poem] }
```

### 3b. JSON files

`poets-catalog.json`:

```json
{"schemaVersion":1,"poets":[
 {"id":2,"slug":"hafez","name":"حافظ","fullName":"حافظ شیرازی","rootCategoryId":9,"bundledPack":"pack-hafez","falCategoryId":24,"birthYearHijri":726,"deathYearHijri":792,"sortOrder":0,"isEnabled":true},
 {"id":7,"slug":"saadi","name":"سعدی","fullName":"سعدی شیرازی","rootCategoryId":118,"bundledPack":"pack-saadi","bundledCategoryIds":[120,123,1665],"falCategoryId":null,"birthYearHijri":615,"deathYearHijri":694,"sortOrder":1,"isEnabled":true},
 {"id":3,"slug":"khayyam","name":"خیام","fullName":"خیام نیشابوری","rootCategoryId":30,"bundledPack":"pack-khayyam","bundledCategoryIds":[31],"falCategoryId":null,"birthYearHijri":439,"deathYearHijri":526,"sortOrder":2,"isEnabled":true},
 {"id":22,"slug":"saeb","name":"صائب","fullName":"صائب تبریزی","rootCategoryId":279,"bundledPack":"pack-saeb","bundledCategoryIds":[282],"falCategoryId":null,"birthYearHijri":1001,"deathYearHijri":1080,"sortOrder":3,"isEnabled":true}]}
```

Adding a poet means adding an entry. To ship it offline as well, run the script with `--poet-id N --slug x` (plus `--only-cats` for a partial pack) and set `bundledPack` and, for a partial pack, `bundledCategoryIds`. A nil or empty `bundledCategoryIds` with a `bundledPack` means the whole poet is bundled (`isFullyBundled`); otherwise the poet is `isPartiallyBundled` and everything outside those categories is served by the remote source. A missing pack file simply routes the poet to remote.

In a partial pack, the root category and every intermediate category on the way to a bundled category are present and navigable. Their children that are not bundled carry `"onlineOnly":true` (`CategoryRef.isOnlineOnly`, encoded only when true), and the UI fetches those from the remote source on demand.

`pack-hafez.json`:
- Minified, UTF-8, `ensure_ascii=False`. Null or empty optional keys are omitted.
- Decode with `decodeIfPresent`.

```json
{"schemaVersion":1,"generatedAt":"2026-10-17T…Z","source":"api.ganjoor.net",
 "poet":{"id":2,"name":"حافظ","fullName":"حافظ شیرازی","slug":"hafez","rootCategoryId":9,"birthYearHijri":726,"deathYearHijri":792},
 "categories":[{"id":9,"poetId":2,"title":"حافظ","slug":"hafez","children":[{"id":24,"title":"غزلیات"},…],"poems":[]},
               {"id":24,"poetId":2,"title":"غزلیات","slug":"ghazal","parentId":9,"children":[],"poems":[{"id":2130,"categoryId":24,"title":"غزل شمارهٔ ۱","urlSlug":"sh1","excerpt":"…","coupletCount":7}]}],
 "poems":[{"id":2130,"poetId":2,"categoryId":24,"title":"غزل شمارهٔ ۱","fullTitle":"حافظ » غزلیات » غزل شمارهٔ ۱","urlSlug":"sh1","fullUrl":"/hafez/ghazal/sh1","summary":"…",
   "couplets":[{"index":0,"kind":"beyt","summary":"…","verses":[{"id":3794588,"order":1,"position":0,"text":"اَلا یا …"},{"id":3794590,"order":2,"position":1,"text":"…"}]}],
   "recitations":[{"id":2840,"artist":"فریدون فرح‌اندوز","mp3Url":"https://i.ganjoor.net/a/2130-ff.mp3","syncUrl":"https://api.ganjoor.net/api/audio/xml/2840","order":1,"type":0,"synced":true}]}]}
```

**Couplet-building algorithm.** Python and Swift `GanjoorMapper` must implement it identically.
1. Sort verses by `vOrder`.
2. For each verse with a non-null `coupletIndex`, append it to the couplet with that index. Couplets are kept in first-seen order.
3. A verse with a null `coupletIndex` becomes its own couplet with `index = -vOrder` and `kind = paragraph`.
4. Set `kind` as follows:
   - 2 or more verses whose first position is in {0, 2} → `beyt`.
   - Exactly 1 verse with position 4 or 0 → `single`.
   - Position −1 (or any other lone verse) → `paragraph`.
5. `summary` is the first non-empty, trimmed `coupletSummary` in the couplet.
6. Text cleanup: strip `\r`, trim whitespace, collapse internal runs of spaces. **Keep ZWNJ and diacritics.**
7. `excerpt` in a poem summary is the first mesra of the poem, taken from the API excerpt.
8. `coupletCount` is the number of memorizable couplets.
9. Recitations: keep only entries with a non-empty `mp3Url`, sorted by `audioOrder`. Map `xmlText` → `syncUrl` and `inSyncWithText` → `synced`.

### 3c. Tools/fetch_ganjoor.py (stdlib only)

- **CLI:** `python3 -I Tools/fetch_ganjoor.py --poet-id 2 --slug hafez [--out AzBar/Resources/Content/pack-hafez.json] [--cache Tools/.cache/poet-2] [--delay 0.5] [--only-cats 24,25] [--no-summaries]`. `--only-cats` accepts category ids at any depth.
- **Fetching:** shells out to `curl -sSfL` (`User-Agent: AzBar-ContentTool/1.0`, 30 s timeout) so it uses the system trust store; Python builds without CA certificates cannot verify TLS through `urllib`. Five attempts with exponential backoff; `--delay` seconds of sleep after every network call (cache hits skip it).
- **Resumable:** every raw response is written to `{cache}/{poet|cat|poem}-{id}.json` and reused on re-runs. A fully cached poet needs no network. `Tools/cache_ganjoor_raw.py <poet-id> <cache-dir>` pre-populates the same cache.
- **Nested selection (`--only-cats`):** for each requested id the script loads `cat-{id}` (fetching only if missing) and reads `cat.ancestors`. `keep = requested ∪ (ancestors − root)`. The root entry lists all root children, adding `onlineOnly:true` to those not in `keep`. Each ancestor is written as a shell category (children annotated the same way, poem summaries without `coupletCount`, no poem bodies) with `parentId` set to its real parent. Each requested category is walked in full, breadth-first. Non-selected categories are never fetched (Saeb's `1852` alone has about 7,000 ghazals). Without `--only-cats` the output is identical to the previous behaviour apart from `generatedAt`. After writing, the script prints a catalog hint line with `bundledCategoryIds`, `birthYearHijri` and `deathYearHijri`.
- **Commands:**
  - `python3 -I Tools/fetch_ganjoor.py --poet-id 3 --slug khayyam --only-cats 31`
  - `python3 -I Tools/fetch_ganjoor.py --poet-id 22 --slug saeb --only-cats 282`
  - `python3 -I Tools/fetch_ganjoor.py --poet-id 7 --slug saadi --only-cats 120,123,1665`
- **Steps:**
  1. `GET /api/ganjoor/poet/{id}` gives the poet and its root category.
  2. Breadth-first over categories: `GET /api/ganjoor/cat/{id}?poems=true`, then recurse into `cat.children`.
  3. For each poem: `GET /api/ganjoor/poem/{id}?verseDetails=true&recitations=true&catInfo=false&rhymes=false&next=false&prev=false&images=false&songs=false&comments=false&navigation=false&relatedpoems=false`.
  4. Map with the algorithm in 3b and write a minified file (`separators=(",",":")`).
  5. Print stats: poem count, couplet count, file size.
- `--no-summaries` omits every Ganjoor poem and couplet summary (the meanings) from the pack.
- **Ordering:** poems follow API order within a category; categories are in breadth-first order.
- **Size guard:** if the output exceeds 15 MB, only the first 8 recitations per poem are kept.
- **Runtime:** a full poet is about 700 requests, roughly 6 to 7 minutes.

### 3d. SwiftData (`Persistence/SchemaV1.swift`)

```swift
enum AzBarSchemaV1: VersionedSchema { static let versionIdentifier = Schema.Version(1,0,0)
  static var models: [any PersistentModel.Type] { [CoupletCard.self, MemorizationPlan.self, ReviewLogEntry.self, FavoritePoem.self, DailyActivity.self] } }
enum AzBarMigrationPlan: SchemaMigrationPlan { static var schemas: [any VersionedSchema.Type] { [AzBarSchemaV1.self] }; static var stages: [MigrationStage] { [] } }
extension AzBarSchemaV1 {
 @Model final class CoupletCard { #Index<CoupletCard>([\.due], [\.poemId])
   @Attribute(.unique) var key: String; var poemId: Int; var poetId: Int; var coupletIndex: Int
   var stateRaw: Int; var stability: Double; var difficulty: Double; var due: Date; var lastReview: Date?
   var reps: Int; var lapses: Int; var createdAt: Date }
 @Model final class MemorizationPlan { @Attribute(.unique) var poemId: Int; var poetId: Int; var title: String; var poetName: String
   var memorizableCount: Int; var nextCoupletIndex: Int /*index of next couplet to learn; -1 if done*/; var addedAt: Date; var lastStudiedAt: Date?; var isArchived: Bool }
 @Model final class ReviewLogEntry { var cardKey: String; var ratingRaw: Int; var reviewedAt: Date; var elapsedDays: Double; var scheduledDays: Double; var stateBeforeRaw: Int; var isLearning: Bool }
 @Model final class FavoritePoem { @Attribute(.unique) var poemId: Int; var poetId: Int; var title: String; var addedAt: Date }
 @Model final class DailyActivity { @Attribute(.unique) var dayKey: String /*yyyy-MM-dd gregorian, local tz*/; var reviewCount: Int; var learnedCount: Int }
}
typealias CoupletCard = AzBarSchemaV1.CoupletCard  // etc.
```

There are no relationships, which keeps the schema simple and safe under Swift 6.

### 3e. AppSettings (`@MainActor @Observable final class`, UserDefaults-backed via `didSet`, keys `settings.*`)

| Property | Type | Default |
|---|---|---|
| `poemFont` | `PoemFont` | `.naskh` |
| `poemFontSize` | `Double` | 22 (range 16–36) |
| `showMeaning` | `Bool` | `true` |
| `showDiacritics` | `Bool` | `true` |
| `remindersEnabled` | `Bool` | `false` |
| `reminderHour` | `Int` | 20 |
| `reminderMinute` | `Int` | 0 |
| `preferredReciter` | `String?` | `nil` |
| `newCoupletsPerSession` | `Int` | 2 (1–5) |
| `dailyReviewLimit` | `Int` | 100 |
| `desiredRetention` | `Double` | 0.9 |

- `var fsrsParameters: FSRSParameters` is derived from these.
- Init: `init(defaults: UserDefaults = .standard)`.

## 4. Memorization engine (AzBarKit)

### 4a. FSRS-5

```swift
public enum Rating: Int, Codable, Sendable, CaseIterable { case again = 1, hard, good, easy }
public enum CardState: Int, Codable, Sendable { case new = 0, learning, review, relearning }
public struct FSRSCard: Codable, Sendable, Hashable { stability, difficulty: Double; due: Date; lastReview: Date?; reps, lapses: Int; state: CardState; static func new(now: Date) -> FSRSCard }
public struct FSRSParameters: Sendable, Hashable { w: [Double]; desiredRetention = 0.9; maximumInterval = 36500; againStepMinutes = 10
  static let defaultW = [0.40255, 1.18385, 3.173, 15.69105, 7.1949, 0.5345, 1.4604, 0.0046, 1.54575, 0.1192, 1.01925, 1.9395, 0.11, 0.29605, 2.2698, 0.2315, 2.9898, 0.51655, 0.6621] }
public struct SchedulingResult: Sendable, Hashable { card: FSRSCard; elapsedDays: Double; scheduledDays: Double /*0 for minute steps*/ }
public struct FSRSScheduler: Sendable { init(parameters: FSRSParameters = .init(), calendar: Calendar = .current)
  func retrievability(_ c: FSRSCard, at now: Date) -> Double
  func next(_ c: FSRSCard, rating: Rating, now: Date) -> SchedulingResult
  func preview(_ c: FSRSCard, now: Date) -> [Rating: SchedulingResult] }
```

**Formulas.** `DECAY = -0.5`, `FACTOR = 19/81`, and `clampD(x) = min(max(x, 1), 10)`.
- Retrievability: `R(t,S) = (1 + FACTOR·t/S)^DECAY`.
- Interval: `I(S) = round(S/FACTOR · (r^(1/DECAY) − 1))`, clamped to `[1, maximumInterval]` days. With r = 0.9, I = S.
- Initial difficulty, raw: `D0raw(G) = w4 − e^(w5·(G−1)) + 1`. Clamped: `D0(G) = clampD(D0raw(G))`.
- Next difficulty: `D' = clampD( w7·D0raw(4) + (1−w7)·(D + (−w6·(G−3))·(10−D)/9) )`.
- Stability after recall: `S'r = S·(e^w8·(11−D)·S^(−w9)·(e^(w10·(1−R))−1)·(G==hard ? w15 : 1)·(G==easy ? w16 : 1) + 1)`.
- Stability after forgetting: `S'f = min( w11·D^(−w12)·((S+1)^w13 − 1)·e^(w14·(1−R)), S / e^(w17·w18) )`.
- Short-term (same-day) stability: `S's = S·e^(w17·(G−3+w18))`.

**Elapsed days.** `t` is the number of whole calendar days between `startOfDay(lastReview)` and `startOfDay(now)`, never below 0. It is 0 for a new card.

**Transitions.** Every rating sets `reps += 1` and `lastReview = now`.
- **New card:**
  - S = w[G−1], D = D0(G).
  - Again → state `.learning`, due = now + 10 min.
  - Hard, Good or Easy → state `.review`, due = now + I(S) days.
- **Learning or relearning card, or a review card with t == 0:**
  - S = S's(G), D = D'.
  - Again → state unchanged (a review card becomes `.relearning`), due = now + 10 min.
  - Otherwise → state `.review`, due = now + I(S).
- **Review card with t > 0:**
  - R = R(t, S).
  - Again → S = S'f, D = D'(1), `lapses += 1`, state `.relearning`, due = now + 10 min.
  - Otherwise → S = S'r(G), D = D'(G), due = now + I.
- **Interval ordering (in `preview` and `next`):** compute hard, good and easy together, then apply:
  - `hard = min(hard, good)`
  - `good = max(good, hard + 1)`
  - `easy = max(easy, good + 1)`
- **Due dates** use `calendar.date(byAdding: .day, value: I, to: now)`.

**Test vectors** (tolerance 1e-3):

| Case | S | D | Interval |
|---|---|---|---|
| New, Again | 0.40255 | 7.1949 | 10 min |
| New, Hard | 1.18385 | 6.4883 | 1 d |
| New, Good | 3.173 | 5.2824 | 3 d |
| New, Easy | 15.69105 | 3.2245 | 16 d |
| New-Good card after t = 3 (R = 0.9047), Hard | 4.9245 | 6.0350 | 5 d |
| Same, Good | 10.7389 | 5.2730 | 11 d |
| Same, Easy | 25.7936 | 4.5110 | 26 d |
| Same, Again | 1.0556 | 6.7969 | lapses = 1, relearning |
| Short-term Good on S = 3.173 | 4.4669 | | |

### 4b. Text and cloze

**`PersianText.normalizeForSearch(_:)`**
1. Remove these characters:
   - U+064B–U+065F
   - U+0670
   - U+06D6–U+06DC, U+06DF–U+06E8, U+06EA–U+06ED
   - U+0640 (tatweel)
   - U+200C (ZWNJ), U+200D, U+200F, U+200E
2. Map:
   - ي U+064A, ى U+0649, ئ U+0626 → ی U+06CC
   - ك U+0643 → ک U+06A9
   - ة U+0629, ۀ U+06C0 → ه U+0647
   - أ, إ, آ, ٱ → ا
   - ؤ → و
   - Persian and Arabic digits → ASCII
3. Collapse whitespace to single spaces and trim.

**`PersianText.removingDiacritics(_:)`** removes only the diacritic ranges above. It keeps ZWNJ and does not map letters. The reader uses it when `showDiacritics` is off.

**`PersianTokenizer.tokenize(_ mesra: String, mesraIndex: Int, startId: Int) -> [MesraToken]`**
- Split on Unicode whitespace only (space, NBSP U+00A0, tab). **ZWNJ is never a separator.**
- Peel leading and trailing punctuation from the set `، ؛ ؟ ! . : « » " ' ( ) [ ] … - – —` into `leading` and `trailing`.
- `MesraToken { id, mesraIndex: Int; text, core, leading, trailing, normalized: String; isWord: Bool /* normalized has ≥1 letter */ }`

**`PersianStopwords.set`** (compared against normalized forms):
و به از که در با را بر تا این آن ای چو چون هر نه من تو او ما شما ز بی یا اگر گر هم است بود شد کز کو مرا ترا تورا همه پس ولی اما باز نیز هست کی چه کجا کین وین زان کان بدان درین وان ام ات اش

**`ClozeEngine`** (`public struct`, Sendable)
- `init(poemId: Int, couplet: Couplet)`
- `let tokens: [[MesraToken]]` holds one array per verse. Ids are global across the couplet, counting from 0.
- `let hidingOrder: [Int]`
- `static let defaultLevels: [Double] = [0, 0.3, 0.6, 1.0]`
- `func hiddenIds(fraction: Double) -> Set<Int>`
- `func hiddenIds(level: Int, levels: [Double] = defaultLevels) -> Set<Int>`
- `static func firstLetterHint(_ t: MesraToken) -> String`

**Seed and hiding order.** Do not use Swift `Hasher`, because it is randomized per process.
1. Seed = FNV-1a-64 over the UTF-8 bytes of `"\(poemId):\(coupletIndex)"` (offset `0xcbf29ce484222325`, prime `0x100000001b3`). This feeds `SplitMix64: RandomNumberGenerator`.
2. For each word token in id order:
   - `len` = character count of `normalized`.
   - `w = stopword ? 0 : (len <= 2 ? 1 : 2 + Double(min(len, 8))/8)`.
   - `jitter = Double(rng.next() >> 11) / 2^53 · 0.99`.
   - `priority = w + jitter`.
3. `hidingOrder` = word ids sorted by priority descending, ties broken by id ascending.

**Count for a fraction f,** where N is the number of word tokens:
- f ≤ 0 → 0
- f ≥ 1 → N
- otherwise `max(1, ceil(f·N))`

`hiddenIds` returns the first k entries of `hidingOrder`. Each level is therefore a superset of the previous one.

**First-letter hint.** `first` is the first `Character` of `core`, which keeps its diacritics. Let r = letters remaining.
- If `first` is a non-joining letter (ا آ أ إ د ذ ر ز ژ و ؤ), return `first + "…"`.
- Otherwise return `first + String(repeating: "ـ", count: min(4, max(1, r)))`.

### 4c. Learn session state machine (`LearnSessionEngine`, Sendable struct)

```swift
public enum LearnStep: Hashable, Sendable { case read, cloze(level: Int /*1...3*/), firstLetters, recallSecond, recallChain }
public struct LearnItem: Hashable, Sendable { coupletIndex: Int; isRetry: Bool }
public struct LearnRatingEvent: Sendable { coupletIndex: Int; rating: Rating }
init(poem: Poem, coupletIndices: [Int])
private(set) var queue: [LearnItem]; private(set) var itemPosition: Int; private(set) var stepPosition: Int; private(set) var isRevealed: Bool
var currentItem: LearnItem?; var currentStep: LearnStep?; var steps(for: LearnItem) -> [LearnStep]
var isRecallStep: Bool; var awaitsRating: Bool /* isRevealed && last step of item */; var isFinished: Bool
var progress: Double /* completed steps / total steps incl. retries */
var learnedCount: Int
mutating func advance()   // only valid when !isRecallStep || (isRevealed && !awaitsRating)
mutating func reveal()
mutating func rate(_ r: Rating) -> LearnRatingEvent  // valid when awaitsRating; Again & !isRetry → append LearnItem(isRetry:true) to queue
```

**Steps per item:**
- **New beyt:** `[.read, .cloze(1), .cloze(2), .cloze(3), .firstLetters, .recallSecond]`, plus `.recallChain` if `poem.previousMemorizable(before:)` is not nil.
- **Single (one-line couplet):** `[.read, .cloze(1), .cloze(2), .cloze(3), .firstLetters]`, plus `.recallChain` if available. If there is no chain, the final step is `.cloze(3)`, and it is treated as a recall step: reveal, then rate.
- **Retry item:** `[.cloze(2), .recallSecond]`, or `[.cloze(2), .cloze(3)]` for a single.

**Rating rules:**
- Rating happens only once per item, on the last step.
- Every rating event is persisted, including the retry rating. The second rating on the same day uses the short-term FSRS path.
- A couplet is retried at most once.

**Which couplets a session teaches** (`LearnModel` in the app): starting at `plan.nextCoupletIndex`, take the next `newCoupletsPerSession` memorizable couplets that have no card yet.

### 4d. Review session (`ReviewSessionEngine`)

```swift
public enum ReviewPromptMode: Sendable { case recallSecond, recallChain, recallFromHints }
public struct ReviewItem: Sendable, Hashable { key: CoupletKey; card: FSRSCard }
init(items: [ReviewItem], scheduler: FSRSScheduler)
var current: ReviewItem?; var position: Int; var total: Int; var isRevealed: Bool; var isFinished: Bool
func mode(for item: ReviewItem, poem: Poem) -> ReviewPromptMode
mutating func reveal(); mutating func rate(_ r: Rating, now: Date) -> SchedulingResult
var counts: [Rating: Int]
```

**Mode selection:**
- `recallChain` if the couplet has a previous memorizable couplet and `card.reps` is odd.
- Otherwise `recallSecond` if the couplet is a beyt.
- Otherwise `recallChain` if available.
- Otherwise `recallFromHints`.

**Again handling:**
- After Again, reinsert the item at `min(position + 3, end)`, carrying the updated card.
- Requeue an item at most twice per session.

**Queue source:** `ProgressStore.dueItems(until: startOfTomorrow, limit: dailyReviewLimit)`, sorted by `(due, poemId, coupletIndex)`.

**`PoemProgress.compute(cards: [FSRSCard], totalMemorizable: Int)`**
- Returns `{ total, notStarted, learning, young, mature }`.
- Young means state `.review` with S < 21. Mature means S ≥ 21.
- `fraction = (0.25·learning + 0.6·young + 1.0·mature) / total`.

## 5. App layer contracts

```swift
// App
@MainActor @Observable final class AppModel {
  let container: ModelContainer; let content: ContentRepository; let progress: ProgressStore
  let settings: AppSettings; let audio: AudioPlayerService; let reminders: ReminderScheduler
  var selectedTab: AppTab = .today; var learnRequest: LearnRequest?; var isReviewPresented = false; var isFalPresented = false
  static func live() -> AppModel   // ModelContainer(for: Schema(versionedSchema: AzBarSchemaV1.self), migrationPlan: AzBarMigrationPlan.self); on error → in-memory
  static func preview() -> AppModel
  func startLearning(poemId: PoemID, poetId: PoetID)   // sets learnRequest
}
enum AppTab: Hashable { case today, library, review, settings }
struct LearnRequest: Identifiable, Hashable { let id = UUID(); let poemId: PoemID; let poetId: PoetID }
extension EnvironmentValues { @Entry var contentRepository: ContentRepository = .empty }
```

**AzBarApp root modifier chain:**
- `RootView()`
- `.environment(model)`, `.environment(model.settings)`, `.environment(model.progress)`, `.environment(model.audio)`
- `.environment(\.contentRepository, model.content)`
- `.environment(\.layoutDirection, .rightToLeft)`
- `.environment(\.locale, Locale(identifier: "fa_IR"))`
- `.environment(\.calendar, Calendar(identifier: .persian))`
- `.font(.app(.body))`
- `.modelContainer(model.container)`

`init()` calls `UIKitAppearance.configure()`. RootView reschedules reminders when `scenePhase` becomes `.background`.

**Kit `ContentRepository`** (`public final class: Sendable`)

```swift
init(catalog: PoetCatalog, bundledPacks: [PoetID: URL], remote: GanjoorRemoteSource)
static let empty: ContentRepository
static func live(bundle: Bundle) -> ContentRepository  // loads poets-catalog.json; maps bundledPack names via bundle.url(forResource:withExtension:"json"); cache dir = Caches/Ganjoor
let catalog: PoetCatalog
func poet(_ id: PoetID) async throws -> Poet
func rootCategory(poetId: PoetID) async throws -> PoemCategory
func category(_ id: CategoryID, poetId: PoetID) async throws -> PoemCategory
func poem(_ id: PoemID, poetId: PoetID) async throws -> Poem
func randomFalPoem(poetId: PoetID) async throws -> Poem          // uses entry.falCategoryId
func search(_ query: String, limit: Int = 100) async -> [SearchHit]   // bundled poets only in v1; query normalized; min 2 chars
func recitationArtists(poetId: PoetID) async -> [String]          // distinct artists sorted by frequency desc (bundled)
public struct SearchHit: Sendable, Hashable, Identifiable { id: String; poemId, poetId: Int; poemTitle: String; coupletIndex: Int?; matchedText: String }
```

**`PoemSource` protocol** (`Sendable`)
- Methods: `poet(id:)`, `rootCategory()`, `category(id:)`, `poem(id:)`, all `async throws`.
- `enum ContentError: Error { notFound, network(String), decoding(String) }`.

**`BundledPoemSource`** is an `actor`.
- `init(packURL: URL)`.
- Loads lazily on first call and builds dictionaries keyed by id.
- Exposes `allPoems() -> [Poem]` for search and artist listing.

**`GanjoorRemoteSource`** is an `actor`.
- `init(session: URLSession = .shared, cacheDirectory: URL, baseURL: URL = https://api.ganjoor.net)`.
- Cache files are `{cache}/{kind}-{id}.json` holding **domain-encoded** JSON. Categories and poet expire after 7 days; poems never expire.
- On a network error it falls back to a stale cache if one exists.

**`RecitationSyncLoader`**
- `func load(_ url: URL, session: URLSession) async throws -> [SyncPoint]`.
- First try to JSON-decode the body as a `String`. If that fails, read the body as UTF-8 XML.
- Then call `RecitationSyncParser.parse(xml:)`, which uses `XMLParser` with a delegate created locally and drops negative VerseOrder values.

**App `ProgressStore`** (`@MainActor @Observable final class`)

```swift
init(container: ModelContainer); private(set) var revision = 0   // bump after every write; read in every query method so views invalidate
func plan(poemId:) -> MemorizationPlan?; func activePlans() -> [MemorizationPlan]
func addPlan(poem: Poem, poetName: String); func removePlan(poemId:) /* also deletes its cards */
func card(_ key: CoupletKey) -> FSRSCard?; func cards(poemId:) -> [CoupletKey: FSRSCard]
func dueItems(until: Date, limit: Int?) -> [ReviewItem]; func dueCount(until: Date) -> Int; func dueCount(on day: Date) -> Int
func nextDueDate() -> Date?
@discardableResult func record(_ rating: Rating, key: CoupletKey, poetId: PoetID, isLearning: Bool, scheduler: FSRSScheduler, now: Date = .now) -> SchedulingResult
func advancePlan(poemId:, to nextIndex: Int)
func progress(poemId:, totalMemorizable: Int) -> PoemProgress
func isFavorite(_ poemId:) -> Bool; func toggleFavorite(poemId:, poetId:, title:); func favorites() -> [FavoritePoem]
func currentStreak(now: Date = .now) -> Int; func hasActivity(on: Date) -> Bool; func todayActivity() -> (reviews: Int, learned: Int)
```

`record` upserts the card (`FSRSCard.new` when none exists), appends a `ReviewLogEntry`, and increments `DailyActivity` (`learnedCount` when `isLearning`, otherwise `reviewCount`). Save explicitly with `try? context.save()`.

**Streak rule:** count consecutive days that have activity. Count backwards from today if today has activity, otherwise from yesterday.

**`ReminderScheduler`** (`@MainActor final class`)
- `requestAuthorization() async -> Bool`
- `authorizationStatus() async -> UNAuthorizationStatus`
- `reschedule(enabled: Bool, hour: Int, minute: Int, store: ProgressStore) async`
  - Removes pending requests with ids `review-reminder-0…6`.
  - If enabled, schedules 7 one-shot `UNCalendarNotificationTrigger`s for the next 7 occurrences of hour:minute.
  - Today's slot is skipped if it has passed, or if today has activity and `dueCount(on:) == 0`.
  - Title: `"وقت مرور"`.
  - Body when cards are due: `"\(n.fa) بیت آمادهٔ مرور است. زنجیرهٔ \(streak.fa) روزه‌تان را نگه دارید."`
  - Body otherwise: `"چند دقیقه با حافظ؛ بیتی تازه از بر کنید."`

**`AudioPlayerService`** (`@MainActor @Observable final class`)

```swift
enum Status: Equatable { case idle, loading, playing, paused, failed(String) }
private(set) var status: Status; private(set) var poemId: PoemID?; private(set) var recitation: Recitation?
private(set) var currentTime: TimeInterval = 0; private(set) var duration: TimeInterval = 0; private(set) var syncPoints: [SyncPoint] = []
var currentVerseOffset: Int?  // last sync point with ms <= currentTime*1000
func load(poem: Poem, recitation: Recitation) async   // AVAudioSession .playback; AVPlayer(url:); if recitation.synced → RecitationSyncLoader
func play(); func pause(); func toggle(); func seek(to: TimeInterval); func skip(by: TimeInterval); func stop()
func seek(toCouplet index: Int, in poem: Poem)        // via sync points
func playCouplet(_ index: Int, in poem: Poem) async   // segment: seek to start, boundary observer at next couplet start → pause
```

- Periodic observer every 0.25 s on `.main`. Use `MainActor.assumeIsolated`.
- Set `MPNowPlayingInfoCenter` with title and artist. Wire play and pause remote commands.
- `RecitationPicker.preferred(_ list: [Recitation], artist: String?) -> Recitation?`: prefer `type == 0`, then a matching artist, otherwise the lowest `order`.

**DesignSystem**

```swift
enum PoemFont: String, CaseIterable, Identifiable, Sendable { case naskh, nastaliq, vazirmatn
  var title: LocalizedStringKey /* "نسخ","نستعلیق","وزیرمتن" */; var regularName: String; var boldName: String /* nastaliq bold = regular */
  func lineSpacing(_ size: CGFloat) -> CGFloat /* naskh .45, nastaliq 1.0, vazir .35 × size */; func verticalPadding(_ size: CGFloat) -> CGFloat /* nastaliq .3×size else 0 */ }
enum AppFontWeight { case regular, medium, semibold, bold; var postScriptName: String /* "Vazirmatn-…" */ }
extension Font { static func app(_ style: Font.TextStyle, weight: AppFontWeight? = nil) -> Font   // .custom(name, size: style.basePointSize, relativeTo: style)
                 static func poem(_ f: PoemFont, size: CGFloat, bold: Bool = false) -> Font }      // relativeTo: .title3
extension Font.TextStyle { var basePointSize: CGFloat }  // largeTitle 34, title 28, title2 22, title3 20, headline 17, body 17, callout 16, subheadline 15, footnote 13, caption 12, caption2 11
// default weights: largeTitle/title/title2 bold, title3/headline semibold, rest regular. Never use .bold() on custom fonts; pass weight.
enum UIKitAppearance { @MainActor static func configure() }  // UINavigationBar.appearance().titleTextAttributes/largeTitleTextAttributes with UIFontMetrics-scaled Vazirmatn (SemiBold 17/Bold 34) — do NOT replace standardAppearance (keeps iOS 26 glass); UISegmentedControl, UIBarButtonItem fonts likewise
enum PersianNumber { static func string(_ n: Int) -> String /* ASCII→U+06F0…U+06F9, grouping "٬" for ≥10000 */; static func digits(_ s: String) -> String }
extension Int { var fa: String }; extension Double { func fa(fractionDigits: Int) -> String /* decimal sep "٫" */ }
enum IntervalFormatter { static func short(_ r: SchedulingResult, from now: Date) -> String } // "۱۰ دقیقه" / "۳ ساعت" / "۵ روز" / "۲ ماه" (≥30d, days/30 rounded) / "۱٫۲ سال"
struct MesraText: View { text: String; font: PoemFont; size: CGFloat; alignment: TextAlignment = .center } // Text(verbatim:), lineSpacing, padding, fixedSize(vertical)
enum CoupletLayout { case stacked, sideBySide }
struct CoupletView: View { couplet: Couplet; layout: CoupletLayout; isHighlighted: Bool = false; showMeaning: Bool; transform: (String) -> String = { $0 } }
```

**CoupletView layouts**
- **stacked** (compact width):
  - Mesra 1 is `.frame(maxWidth: .infinity, alignment: .leading)`, which is the right side in RTL.
  - Mesra 2 is aligned `.trailing`, the left side.
  - Spacing is 6 pt. This is the classic staggered look.
- **sideBySide:** `HStack(spacing: 28)` with two mesras, each `maxWidth: .infinity`, centered. In RTL the first mesra sits on the right.
- **Choosing the layout:** the reader measures its width with `onGeometryChange`. It uses `sideBySide` when width ≥ 700 and `!dynamicTypeSize.isAccessibilitySize`.
- **single and paragraph couplets** are centered.
- **Meaning:** shown below the couplet in `Font.app(.subheadline)` with `.secondary` style. It is collapsible per couplet with a chevron button.
- **Highlight:** `RoundedRectangle(16).fill(.tint.opacity(0.12))` with an animation.
- **Accessibility:** `.accessibilityElement(children: .combine)` with label `"مصراع اول: … مصراع دوم: …"`.

**Liquid Glass usage (HIG):** glass is used only for the floating control layer, not for content cards.
- Content cards use `.background(.background.secondary, in: .rect(cornerRadius: 20))`.
- Glass appears on:
  - the PlayerBar, via `GlassEffectContainer` plus `.glassEffect(.regular.interactive(), in: .capsule)`;
  - primary CTAs with `.buttonStyle(.glassProminent)`;
  - secondary actions with `.buttonStyle(.glass)`;
  - RatingBar buttons with `.glass`, tinted red (Again), orange (Hard), green (Good) and blue (Easy);
  - the Fal hold button.
- Toolbars and the tab bar get glass automatically. The `TabView` uses `.tabBarMinimizeBehavior(.onScrollDown)`. Use `ToolbarSpacer` to group toolbar items.

## 6. Screens

**RootView**
- `TabView(selection: $model.selectedTab)` with four tabs:
  - `Tab("امروز", systemImage: "sun.max", value: .today)`
  - `Tab("کتابخانه", systemImage: "books.vertical", value: .library)`
  - `Tab("مرور", systemImage: "rectangle.stack", value: .review)` with `.badge(dueCount)`
  - `Tab("تنظیمات", systemImage: "gearshape", value: .settings)`
- Each tab has its own `NavigationStack`.
- Presentation modifiers:
  - `.fullScreenCover(item: $model.learnRequest) { LearnView }`
  - `.fullScreenCover(isPresented: $model.isReviewPresented) { ReviewSessionView }`
  - `.sheet(isPresented: $model.isFalPresented) { FalView }` with `.presentationDetents([.large])`
- `LibraryRoute.libraryDestinations()` is applied in the Today and Library stacks.

**Today** (`TodayView`)
- Large title "امروز". The screen is a `List(.insetGrouped)`.
- **StreakCard section:** `flame.fill` with `.symbolEffect(.bounce)` when the streak increases.
  - Streak line: "\(n.fa) روز پیاپی".
  - Due line: "\(due.fa) بیت برای مرور".
  - CTA "شروع مرور" (`.glassProminent`) sets `isReviewPresented`. It is disabled when nothing is due.
  - When nothing is due: "امروز مروری ندارید".
- **Section "در حال حفظ":** rows of title, poet name, `ProgressView(value:)` and "\(learned.fa) از \(total.fa) بیت". Tapping a row calls `startLearning`. Swipe action "حذف" with a confirmation dialog.
- **Section "فال حافظ":** a row with `sparkles` and the text "نیت کنید و دیوان را بگشایید". It opens the sheet.
- **Section "علاقه‌مندی‌ها":** pushes `.poem`.
- **Empty state:** `ContentUnavailableView("هنوز شعری برای حفظ برنگزیده‌اید", systemImage: "text.book.closed", description: Text("از کتابخانه غزلی برگزینید و «حفظ کن» را بزنید"))` with a button "رفتن به کتابخانه".

**Library**
- Title "کتابخانه". A `List` of catalog poets.
  - Row: name (`.app(.headline)`), fullName, lifespan "\(birth.fa) – \(death.fa) ق".
  - Badge "آفلاین" (`arrow.down.circle`) for bundled poets, "آنلاین" (`icloud`) for remote ones.
- `.searchable(text:, prompt: "جستجوی شعر یا مصراع")` with `.task(id: query)` and a 250 ms debounce. Results come from `SearchResultsView` (title plus matched mesra).
- **PoetView:** the children of the root category.
- **CategoryView:** sections "بخش‌ها" and "اشعار". `PoemRow` shows title and a one-line excerpt, with a trailing `heart.fill` or `brain.head.profile` status icon. Local `.searchable` with prompt "جستجو در \(title)".
- **Remote states:**
  - Loading: `ProgressView`.
  - Error: `ContentUnavailableView("اتصال برقرار نشد", systemImage: "wifi.slash")` with a "تلاش دوباره" button.

**Reader** (`ReaderView(poemId:poetId:)`)
- Navigation title is the poem title, `.inline`.
- **Toolbar:**
  - Favourite toggle: `heart` / `heart.fill`, with `.sensoryFeedback(.selection)`.
  - Menu `ellipsis.circle` containing: Toggle "نمایش معنی"; Toggle "نمایش اعراب"; `ShareLink("اشتراک‌گذاری", item: poem.plainText)`; `Link("مشاهده در گنجور", destination: poem.ganjoorURL)`.
- **Content:** `ScrollView` / `LazyVStack(spacing: 22)`.
  - `ReaderHeaderView`: fullTitle and a collapsible "دربارهٔ این شعر" card with the poem summary.
  - A `CoupletView` per couplet. Memorized couplets show a small `checkmark.circle.fill` status.
  - Footer: "منبع: گنجور".
- **Bottom `.safeAreaInset`:** a `GlassEffectContainer` with an `HStack` of the `PlayerBar` capsule and a CTA.
  - PlayerBar: play/pause `play.fill`/`pause.fill`, a reciter `Menu` labelled "خوانش: \(artist)", elapsed and total time in Persian digits, `gobackward.10`.
  - CTA: "حفظ کن" (`.glassProminent`) when there is no plan, or "ادامهٔ حفظ" when there is one.
  - The bar collapses to the play button alone when the tab bar is minimized (derived from scroll state).
  - Tapping "حفظ کن" adds the plan, then calls `startLearning`.
- **Audio sync:**
  - The couplet for `audio.currentVerseOffset` is highlighted. `ScrollViewReader` auto-scrolls to it with `.scrollPosition`.
  - Tapping a couplet while playing seeks to it.
  - Context menu on a couplet: "کپی بیت", "پخش از این بیت".

**Learn** (`fullScreenCover`, `NavigationStack`)
- **Toolbar:** leading `xmark` "بستن", which asks with `confirmationDialog("جلسه را ترک می‌کنید؟")` offering "ترک جلسه" (destructive) and "ادامه". Principal: "بیت \(i.fa) از \(n.fa)". A thin `ProgressView(value: engine.progress)` sits under it.
- **Step headings:**
  - read: "بخوان و گوش کن"
  - cloze: "جاهای خالی را به یاد آور · مرحلهٔ \(l.fa) از ۳"
  - firstLetters: "با حرف نخست هر واژه"
  - recallSecond: "مصراع دوم را به یاد آور"
  - recallChain: "بیت بعد چیست؟"
- **Body by step:**
  - read: `CoupletView`, a "معنی" button that toggles the summary, and "پخش این بیت" (`speaker.wave.2`) when sync is available.
  - cloze / firstLetters: `ClozeMesraView` (`FlowLayout` of tokens). Hidden tokens keep their width: the token text is drawn at opacity 0 over a `.quaternary` capsule. Tap to peek for 1.5 s with `.sensoryFeedback(.impact(weight: .light))`. Accessibility label "واژهٔ پنهان" with a reveal action.
  - recall steps: the prompt mesra or the previous couplet (dimmed for chain), plus a dashed rounded rectangle placeholder showing "؟".
- **Bottom glass bar:**
  - Non-recall steps: "بعدی" (`.glassProminent`).
  - Recall steps before reveal: "نمایش".
  - After reveal on the last step: `RatingBar` titled "چقدر خوب به یاد آوردید؟" with buttons "دوباره", "سخت", "خوب", "آسان". Each shows `IntervalFormatter.short` underneath. Haptics: `.success` for Good/Easy, `.warning` for Again.
- **Summary:** `LearnSummaryView` shows "آفرین!" with `checkmark.seal.fill` and "\(n.fa) بیت تازه از بر شد". Buttons: "ادامهٔ حفظ" (next batch, hidden when the poem is complete) and "پایان". When the poem is finished: "همهٔ بیت‌های این شعر را آموختید".
- **FlowLayout** is a custom `Layout` with wrapping and spacing at 0.28 × font size. It relies on SwiftUI's automatic RTL mirroring of custom layouts; verify in an RTL preview.

**Review**
- **ReviewHomeView**, title "مرور":
  - Due count, "شروع مرور" (`.glassProminent`), a "\(n.fa) بیت امروز" line, and a list of plans with a `ProgressRing`.
  - Empty state: `ContentUnavailableView("مروری باقی نمانده", systemImage: "checkmark.seal", description: "مرور بعدی: \(relative date)")`.
- **ReviewSessionView:** same chrome as Learn. Principal text: "\(pos.fa) از \(total.fa)". Steps: prompt, then "نمایش پاسخ", then `RatingBar`.
- **ReviewSummaryView:** "مرور امروز تمام شد" plus per-rating counts and the streak flame.

**Fal** (`FalView`)
- **Phase 1:** `book.closed.fill` with `.symbolEffect(.breathe)`. Title "فال حافظ". The niyyat text, verbatim: «ای حافظ شیرازی! تو محرم هر رازی! تو را به خدا و به شاخ نباتت قسم می‌دهم که هر چه صلاح و مصلحت می‌بینی برایم آشکار و آرزوی مرا برآورده سازی.» Caption "نیت کنید و دکمه را نگه دارید".
  - `HoldToConfirmButton("نیت کردم")`: 1.2 s long press, an animated ring trim, and haptics. For VoiceOver the `accessibilityAction` fires immediately.
- **Phase 2:** "در حال گشودن دیوان…" with a book symbol `.wiggle` for 1.2 s. With Reduce Motion, use a fade instead. Meanwhile `randomFalPoem` runs.
- **Phase 3:** header "فال شما: \(title)", the poem couplets (`CoupletView`), and a "تفسیر" card with the poem summary.
- **Glass bottom actions:** "پخش" (glass), "حفظ کن" (glassProminent; dismisses the sheet and starts learning), `ShareLink` "اشتراک‌گذاری", and toolbar "فال دوباره" (`arrow.clockwise`).

**Settings** (`Form`, title "تنظیمات")
- **Section "قلم شعر":**
  - `Picker("قلم", selection:)` using the inline style, with options نسخ / نستعلیق / وزیرمتن.
  - `Slider` "اندازهٔ قلم" from 16 to 36, with value shown via `.fa`.
  - Live preview of the first beyt of the sample poem.
- **Section "نمایش":** Toggles "نمایش معنی بیت‌ها" and "نمایش اعراب".
- **Section "یادآوری":**
  - Toggle "یادآوری روزانهٔ مرور". Turning it on requests authorization.
  - `DatePicker("ساعت یادآوری", displayedComponents: .hourAndMinute)`.
  - If authorization is denied: footer "اجازهٔ اعلان داده نشده است" with a `Link` to `UIApplication.openSettingsURLString`.
- **Section "حفظ":**
  - `Stepper("بیت‌های تازه در هر جلسه: \(n.fa)", 1…5)`.
  - `Picker("هدف یادسپاری")` with options ۸۵٪ / ۹۰٪ / ۹۵٪.
  - `Stepper("سقف مرور روزانه")` from 20 to 500 in steps of 10.
- **Section "خوانش":** `Picker("خوانندهٔ ترجیحی")` with "خودکار" plus the list from `recitationArtists(poetId: 2)`.
- **Section "دربارهٔ برنامه":** `NavigationLink("دربارهٔ ازبر")` to `AboutView`, which contains the Ganjoor attribution with a link, the open-source links (source code, issue tracker, privacy policy) and the MIT licence note, font credits (Vazirmatn, Noto Naskh Arabic, Noto Nastaliq Urdu, SIL OFL 1.1), and the version number.

**Other UI rules**
- Every icon-only button needs `.accessibilityLabel` in Persian.
- Support Dynamic Type up to AX5; reader and learn views scroll.
- Use system semantic colors so dark mode works.
- `ProgressView` tint uses AccentColor.

## 7. Ganjoor API notes

Base URL `https://api.ganjoor.net`; recitation audio is hosted on `https://i.ganjoor.net`.

- **Poem shape.** `versePosition` values seen in Hafez are 0 and 1 (and 2, 4, -1 elsewhere); `coupletIndex` is 0-based; `vOrder` is 1-based. Recitation fields: `id, audioArtist, mp3Url, xmlText, audioOrder, recitationType, inSyncWithText`.
- **Sync data quirk.** `GET /api/audio/xml/{recitationId}` (for example `/api/audio/xml/2840`) returns a JSON-encoded string that contains XML: `<DesktopGanjoorPoemAudioList><PoemAudio>…<SyncArray><SyncInfo><VerseOrder>0</VerseOrder><AudioMiliseconds>0</AudioMiliseconds>`. `VerseOrder` is a 0-based index into the verses sorted by `vOrder`. Ghazal 1 has 14 verses and `VerseOrder` runs 0 to 13. Negative values and `<OneSecondBugFix>` are ignored.
- **MP3 hosting.** Files live at `https://i.ganjoor.net/a/...mp3`. The server sends `accept-ranges: bytes`, so `AVPlayer` can stream and seek.
- **Hafez categories** (poet id 2, root category 9):

  | id | Category | Poems |
  |---|---|---|
  | 24 | غزلیات | 495 |
  | 25 | قطعات | 34 |
  | 26 | رباعیات | 42 |
  | 27 | قصاید | 3 |
  | 674 | اشعار منتسب | 118 |

  The total is 692 poems and none of these categories has subcategories. Fal-e Hafez draws only from غزلیات (24).
- **Other poets.**

  | Poet | id | Root | Bundled categories | Notes |
  |---|---|---|---|---|
  | Saadi | 7 | 118 | 120 (ghazals, 637), 123 (11 children), 1665 (8 children) | Parent `119` is shallow; Bustan and Golestan contain prose paragraphs |
  | Khayyam | 3 | 30 | 31 (rubaiyat, 178; 2 memorizable couplets each) | Other root children are `onlineOnly` |
  | Saeb | 22 | 279 | 282 (1,542 single beyts) | Parent `280` is shallow; its other children (for example `1852`, 6,995 ghazals) are `onlineOnly` |
- **Bundled packs.** All five Hafez categories ship in `pack-hafez.json`; Khayyam, Saeb and Saadi ship the selected categories above in `pack-{khayyam,saeb,saadi}.json` (texts, couplet summaries and recitation metadata). Audio is streamed, never bundled.

## 8. Tests and commands

**Kit tests** (Swift Testing, `Packages/AzBarKit/Tests/AzBarKitTests/`, run on the macOS host):
- **FSRSSchedulerTests:** all §4a vectors; interval ordering hard < good < easy; Again on a new card gives a 10-minute step; `R(S, t=S)` ≈ 0.9; clamping of D and maximum interval; `preview` matches `next`.
- **ClozeEngineTests:**
  - determinism: two separate instances give equal results, and different poem ids give different orders;
  - levels are nested supersets; level 0 is empty and level 3 is all words;
  - the 30% level hides at least one word;
  - stopwords are never hidden while a content word remains visible (levels below 1.0);
  - "می‌خواهم" (with ZWNJ) is one token;
  - punctuation is peeled;
  - the first-letter hint works for joining and non-joining letters.
- **PersianTextTests:** diacritic removal on "اَلا یا اَیُّهَا"; ي/ك mapping; ZWNJ removed only by search normalization; digits mapped.
- **GanjoorMapperTests:** the 2130 fixture yields 7 couplets of kind beyt; index 0 has 2 verses with the right summary; recitations mapped and sorted; a synthetic paragraph verse gets a negative index.
- **ContentPackDecodingTests and BundledPoemSourceTests:** `pack-mini` round-trip; category, poem and `notFound` lookups.
- **SearchIndexTests:** a query without diacritics finds a mesra that has them; a ZWNJ-insensitive match.
- **RecitationSyncTests:** the fixture parses to 14 points with ms[1] = 7386; a raw-XML body also parses.
- **LearnSessionEngineTests:** step sequence for the first couplet (no chain) and the second (with chain); Again appends one retry, a second Again on the retry does not; `progress` is monotonic.
- **ReviewSessionEngineTests:** Again requeues at +3 and at most twice; `isFinished`.

**App tests** (`AzBarTests`):
- ProgressStore record/upsert and due queries.
- Streak: today-only, gap, and yesterday-continuation cases.
- `removePlan` cascades to cards.
- PersianNumber.
- AppSettings persistence with a suite-named UserDefaults.
- Bundled `pack-hafez` loads and has 692 poems (or the count the script printed).

**Commands**
- `swift test --package-path Packages/AzBarKit` runs the kit tests on the host.
- `xcodebuild -project AzBar.xcodeproj -scheme AzBar -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build-for-testing` compiles the app and its test target.
- Running the app tests needs an iOS 26+ simulator runtime (`xcodebuild -downloadPlatform iOS`), then: `xcodebuild test -project AzBar.xcodeproj -scheme AzBar -destination 'platform=iOS Simulator,name=iPhone 17'`.

**Notes**
- Use no API introduced after iOS 26.0; the deployment target is 26.0.
- Remote poets are not included in search.
- Before an App Store release, confirm the licensing of the Ganjoor couplet summaries and recitations (see `docs/appstore/content-licensing.md`).
