# Questionnaire answers

## Age rating

Answer every question "None" / "No" except the first below, then accept the computed rating.

| Question | Answer | Why |
|---|---|---|
| Alcohol, tobacco or drug use or references | **Infrequent / Mild** | Classical Persian poetry, Hafez above all, mentions wine as a literary and mystical image. |
| Violence (cartoon, realistic, graphic) | None | |
| Sexual content or nudity | None | |
| Profanity or crude humor | None | |
| Horror / fear themes | None | |
| Mature / suggestive themes | None | |
| Medical or treatment information | None | |
| Gambling (real or simulated) | None | |
| Contests | None | |
| Unrestricted web access | No | Links (Ganjoor, GitHub, privacy policy) open in Safari; there is no in-app browser. |
| User-generated content | No | |
| Messaging or chat | No | |
| Advertising | No | |
| Parental controls | No | |
| Age assurance | No | |

Re-check the form in App Store Connect when submitting: Apple changes the age-rating questions from time to time. If a question here no longer exists, answer the closest equivalent conservatively.

## App Privacy

- **Data collection: Data Not Collected.**
- Tracking: No. Tracking domains: none.
- Third-party SDKs: none.
- The app has no accounts, analytics, crash reporting or ads. Progress, favourites and settings stay on the device.
- To show non-bundled poets and to play recitations, the app fetches content directly from Ganjoor (api.ganjoor.net, i.ganjoor.net). These are content downloads; the developer receives no data. Ganjoor sees ordinary network metadata such as the IP address, as any website would. This is described in [PRIVACY.md](../../PRIVACY.md).
- The bundle includes `PrivacyInfo.xcprivacy` declaring the required-reason APIs used: UserDefaults (CA92.1) and file timestamp (C617.1).

## Export compliance

- Uses encryption: only standard HTTPS (the OS networking stack), so the app qualifies for the exemption.
- `ITSAppUsesNonExemptEncryption` is already `false` in Info.plist, so no question is asked on upload.

## Content rights

- "Does your app contain, show or access third-party content?" **Yes.**
- "Do you have the necessary rights to use it?" Answer only after [content-licensing.md](content-licensing.md) is resolved. Do not answer Yes before there is written permission, or a build without the contested content.
