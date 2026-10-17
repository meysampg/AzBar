import SwiftUI

extension BadgeID {
    var title: String {
        switch self {
        case .firstLesson: "نخستین گام"
        case .perfectLesson: "بی‌لغزش"
        case .firstGhazal: "نخستین غزل"
        case .tenGhazals: "دیوان‌دار"
        case .firstChallenge: "غزل‌خوان"
        case .streak3: "سه روز پیاپی"
        case .streak7: "یک هفته پیوسته"
        case .streak30: "یک ماه وفاداری"
        case .reviews100: "صد مرور"
        case .reviews500: "پانصد مرور"
        case .mature50: "ماندگار"
        case .level10: "پلهٔ دهم"
        case .nightOwl: "شب‌زنده‌دار"
        case .earlyBird: "سحرخیز"
        case .falSeeker: "فال‌بین"
        }
    }

    var detail: String {
        switch self {
        case .firstLesson: "نخستین درس را به پایان بردید"
        case .perfectLesson: "درسی را بی هیچ اشتباهی تمام کردید"
        case .firstGhazal: "همهٔ بیت‌های یک شعر را آموختید"
        case .tenGhazals: "ده شعر را کامل آموختید"
        case .firstChallenge: "آزمون پایانی یک شعر را با موفقیت گذراندید"
        case .streak3: "سه روز پشت سر هم تمرین کردید"
        case .streak7: "یک هفته بی‌وقفه تمرین کردید"
        case .streak30: "سی روز پیاپی تمرین کردید"
        case .reviews100: "صد بیت را مرور کردید"
        case .reviews500: "پانصد بیت را مرور کردید"
        case .mature50: "پنجاه بیت در حافظهٔ بلندمدت شما نشست"
        case .level10: "به سطح ۱۰ رسیدید"
        case .nightOwl: "پس از ساعت ۲۲ درسی را تمام کردید"
        case .earlyBird: "پیش از ساعت ۷ صبح درسی را تمام کردید"
        case .falSeeker: "پنج بار دیوان حافظ را گشودید"
        }
    }

    var systemImage: String {
        switch self {
        case .firstLesson: "figure.walk"
        case .perfectLesson: "star.fill"
        case .firstGhazal: "book.closed.fill"
        case .tenGhazals: "books.vertical.fill"
        case .firstChallenge: "crown.fill"
        case .streak3: "flame"
        case .streak7: "flame.fill"
        case .streak30: "flame.circle.fill"
        case .reviews100: "rectangle.stack.fill"
        case .reviews500: "square.stack.3d.up.fill"
        case .mature50: "leaf.fill"
        case .level10: "graduationcap.fill"
        case .nightOwl: "moon.stars.fill"
        case .earlyBird: "sunrise.fill"
        case .falSeeker: "sparkles"
        }
    }

    var tint: Color {
        switch self {
        case .firstLesson, .mature50: Theme.Palette.success
        case .perfectLesson, .firstChallenge: Theme.Palette.gold
        case .firstGhazal, .falSeeker: Theme.Palette.teal
        case .tenGhazals, .reviews500, .nightOwl: Theme.Palette.plum
        case .streak3, .streak7, .earlyBird: Theme.Palette.flame
        case .streak30: Theme.Palette.danger
        case .reviews100, .level10: Theme.Palette.info
        }
    }

    /// Symbol colour on a filled tint (ink on gold, white otherwise).
    var symbolColor: Color {
        switch self {
        case .perfectLesson, .firstChallenge: Theme.Palette.ink
        default: .white
        }
    }
}

enum LevelText {
    static func title(level: Int) -> String {
        switch level {
        case ..<5: "نوآموز"
        case 5..<10: "شاگرد"
        case 10..<20: "غزل‌دان"
        case 20..<30: "سخن‌شناس"
        default: "سخن‌دان"
        }
    }
}

enum DailyGoalText {
    static func title(_ goal: Int) -> String {
        switch goal {
        case ..<20: "سبک"
        case 20..<30: "معمولی"
        case 30..<50: "جدی"
        default: "سخت‌کوش"
        }
    }
}
