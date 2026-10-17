# Content licensing

Decide this before the first App Store submission. The app's code is MIT; the content is not entirely ours.

## What we know

| Content | Status |
|---|---|
| Hafez's poem text | Public domain (classical poetry). |
| Meanings and per-poem summaries (from Ganjoor) | May carry rights belonging to Ganjoor or its contributors. |
| Recitation audio and sync (timing) files | May carry rights belonging to Ganjoor and the reciters. |

The bundled Hafez pack (`AzBar/Resources/Content/pack-hafez.json`) redistributes the summaries, both inside the app and in this public repository. Recitations are not bundled: they are streamed from i.ganjoor.net.

## Action before the App Store

Ask Ganjoor (contact details on ganjoor.net, or open an issue at github.com/ganjoor/GanjoorService) for written permission to:

1. Bundle Ganjoor's meanings and summaries in a free, ad-free, MIT-licensed app and repository, with attribution.
2. Stream recitations from i.ganjoor.net inside the app, with the reciters' names shown.

Record the answer here (date, who replied, exact wording, link):

- Date asked: _not yet sent_
- Reply: _pending_

## Fallback if permission is refused or never arrives

- Regenerate the pack without summaries: `python3 -I Tools/fetch_ganjoor.py --poet-id 2 --slug hafez --no-summaries` (check the script's `--help` for the exact flags), commit the new pack and rebuild.
- Keep streaming recitations with attribution only if that part is permitted; otherwise hide the player.
- Answer the "Content rights" question according to what actually ships.

## Where attribution appears

- Settings, About («دربارهٔ از بر»), section «منبع شعرها»
- Reader: the «مشاهده در گنجور» link on each poem
- Fal result: «منبع: گنجور»
- README ("Credits & licences")
- The App Store description ("courtesy of Ganjoor")

## Draft message to Ganjoor

Persian:

```
سلام و احترام،

من میثم پورگنجی هستم، سازندهٔ «از بر»، برنامه‌ای رایگان و متن‌باز (مجوز MIT) برای آیفون که به حفظ کردن شعر فارسی کمک می‌کند، با دیوان حافظ. بدون تبلیغ است، چیزی از کاربران جمع نمی‌کند و کدش اینجاست: https://github.com/meysampg/AzBar

برنامه متن شعرها، معنی و چکیدهٔ شعرها و خوانش‌ها را از گنجور می‌گیرد و در همهٔ جاها از گنجور و خوانندگان نام می‌برد و پیوند به صفحهٔ هر شعر در ganjoor.net می‌گذارد. می‌خواهم پیش از انتشار در اپ استور، به‌طور مشخص دو چیز را بپرسم:

۱. آیا اجازه هست معنی بیت‌ها و چکیدهٔ شعرهای گنجور را، با ذکر منبع، در این برنامهٔ رایگان و متن‌باز و در مخزن کد آن بگنجانم؟
۲. آیا اجازه هست خوانش‌ها را از i.ganjoor.net، با نمایش نام خواننده، در برنامه پخش کنم؟

اگر شرط یا خواستهٔ دیگری دارید، با کمال میل رعایت می‌کنم. سپاس از زحمت‌هایی که برای گنجور می‌کشید.

با احترام
Meysam Pourganji
```

English:

```
Hello,

I am Meysam Pourganji, the author of AzBar («از بر»), a free, open-source (MIT) iPhone app for memorizing Persian poetry, starting with Hafez. It has no ads, collects no user data, and the code is at https://github.com/meysampg/AzBar

The app uses poem texts, couplet meanings, poem summaries and recitations from Ganjoor, credits Ganjoor and the reciters in the app, and links each poem back to its page on ganjoor.net. Before publishing to the App Store I would like to ask two specific questions:

1. May I include Ganjoor's meanings and poem summaries, with attribution, in this free, open-source app and in its public repository?
2. May the app stream recitations from i.ganjoor.net, showing the reciter's name?

If you have any conditions or preferences, I will gladly follow them. Thank you for the work you put into Ganjoor.

Kind regards,
Meysam Pourganji
```
