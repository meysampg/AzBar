# Releasing AzBar

## Prerequisites

- Archiving for distribution and uploading to App Store Connect require the paid
  Apple Developer Program. A free Personal Team can only run debug builds on your own device.
- Xcode 26 or newer. Signing team: `N9GSW3M5U8` (see `Config/ExportOptions-AppStore.plist`).
- Listing text, questionnaires and screenshots: see `docs/appstore/`.

## 1. Bump the version

In the AzBar target build settings (`AzBar.xcodeproj/project.pbxproj`, Debug and Release):

- `MARKETING_VERSION`: the user-visible version, e.g. `1.0`.
- `CURRENT_PROJECT_VERSION`: the build number; must increase for every upload.

## 2. Release sanity build

```sh
xcodebuild -project AzBar.xcodeproj -scheme AzBar -configuration Release \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

Inspect the built app (under DerivedData `Build/Products/Release-iphonesimulator/AzBar.app`):

```sh
plutil -p AzBar.app/Info.plist        # bundle id, display name, UIBackgroundModes, orientations
ls AzBar.app/PrivacyInfo.xcprivacy AzBar.app/Assets.car
```

## 3. Archive

```sh
xcodebuild -project AzBar.xcodeproj -scheme AzBar -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/AzBar.xcarchive archive
```

## 4. Export / upload

```sh
xcodebuild -exportArchive -archivePath build/AzBar.xcarchive \
  -exportPath build/export -exportOptionsPlist Config/ExportOptions-AppStore.plist
```

Alternatively open the archive in Xcode Organizer and choose Distribute App.

## 5. App Store Connect

Fill in the listing, privacy and review information using the materials in `docs/appstore/`.
