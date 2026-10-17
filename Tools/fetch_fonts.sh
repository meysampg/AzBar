#!/bin/bash
# Downloads the static fonts and OFL licences used by AzBar into AzBar/Resources/Fonts.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/AzBar/Resources/Fonts"
mkdir -p "$OUT"
VAZIR="https://github.com/rastikerdar/vazirmatn/raw/master/fonts/ttf"
NOTO="https://github.com/notofonts/notofonts.github.io/raw/main/fonts"
get() { echo "-> $2"; curl -fL --retry 3 -sS -o "$OUT/$2" "$1"; }
for w in Regular Medium SemiBold Bold; do get "$VAZIR/Vazirmatn-$w.ttf" "Vazirmatn-$w.ttf"; done
get "$NOTO/NotoNaskhArabic/hinted/ttf/NotoNaskhArabic-Regular.ttf" NotoNaskhArabic-Regular.ttf
get "$NOTO/NotoNaskhArabic/hinted/ttf/NotoNaskhArabic-Bold.ttf" NotoNaskhArabic-Bold.ttf
get "$NOTO/NotoNastaliqUrdu/hinted/ttf/NotoNastaliqUrdu-Regular.ttf" NotoNastaliqUrdu-Regular.ttf
get "https://github.com/rastikerdar/vazirmatn/raw/master/OFL.txt" Vazirmatn-OFL.txt
get "https://github.com/google/fonts/raw/main/ofl/notonaskharabic/OFL.txt" NotoNaskhArabic-OFL.txt
get "https://github.com/google/fonts/raw/main/ofl/notonastaliqurdu/OFL.txt" NotoNastaliqUrdu-OFL.txt
echo "done"
