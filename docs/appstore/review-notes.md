# Notes for App Review

Paste the "Review notes" block into App Store Connect. The rest of this file is for us.

## Review notes (paste this)

```
AzBar («از بر») helps people memorize Persian poetry, starting with the Divan of Hafez. The interface is in Persian and laid out right-to-left; the tab names are Today «امروز», Library «کتابخانه», Review «مرور», Settings «تنظیمات».

No login, account or in-app purchase exists. The app is free and open source: https://github.com/meysampg/AzBar

Connectivity: the complete Divan of Hafez is bundled and works offline. Saadi and Khayyam, and the audio recitations, need an internet connection (content is fetched from ganjoor.net; no user data is sent).

HOW TO TEST
1. Open the Library tab «کتابخانه», tap «حافظ», then «غزلیات», then «غزل شمارهٔ ۱».
2. Tap «حفظ کن» (Memorize). The Learn flow opens. Tap through the steps (for example «نمایش» to reveal, «بعدی» for next). At the recall steps rate yourself with the four buttons at the bottom: «دوباره» (Again), «سخت» (Hard), «خوب» (Good), «آسان» (Easy).
3. Close the Learn flow with the X button at the top. Open the Review tab «مرور» and tap «شروع مرور» to review what you rated. Rated verses return on later days, so on a fresh install the Review tab may say nothing is due.
4. Today tab «امروز» shows the streak and the poems being memorized.

BACKGROUND AUDIO
The app declares the audio background mode only for poem recitations. To see it: open a poem in the Reader, start a recitation with the player bar at the bottom (internet required), lock the device; playback continues and can be controlled from the lock screen.

REMINDERS
Optional. In Settings «تنظیمات» switch on «یادآوری روزانهٔ مرور» to get one local notification per day at a chosen time. No remote notifications, no server.

FAL-E HAFEZ
On the Today tab, the «فال حافظ» button opens a screen where the user holds a button («نیت کردم») and receives a random ghazal of Hafez to read and memorize. This is a traditional Persian literary and cultural custom, like drawing a random page from a book of poetry. It makes no predictions or claims about the future, and no payments are involved.

PRIVACY
No data is collected. Progress, favourites and settings stay on the device. Privacy policy: https://github.com/meysampg/AzBar/blob/main/PRIVACY.md
```

## Accessibility (fill in after the manual pass)

Do not declare any Accessibility Nutrition Label that has not been verified on a device or simulator. Record each result below and declare only what passes.

| Check | Result | Notes |
|---|---|---|
| VoiceOver: Reader, player bar | _todo_ | |
| VoiceOver: Learn flow (reveal, next, recall steps) | _todo_ | |
| VoiceOver: Review session and the four-button rating bar | _todo_ | |
| Dynamic Type up to AX5 (check Nastaliq text for clipping, rating bar turns into 2 columns) | _todo_ | |
| Reduce Motion | _todo_ | |
| Dark mode | _todo_ | |
| Sufficient contrast (light and dark) | _todo_ | |
| Differentiate without colour (rating buttons carry text, not only colour) | _todo_ | |

Declared labels in App Store Connect (list only the verified ones): _none yet_
