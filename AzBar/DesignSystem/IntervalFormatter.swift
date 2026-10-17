import Foundation

enum IntervalFormatter {
    /// "۱۰ دقیقه" / "۳ ساعت" / "۵ روز" / "۲ ماه" / "۱٫۲ سال"
    static func short(_ r: SchedulingResult, from now: Date) -> String {
        let seconds = max(0, r.card.due.timeIntervalSince(now))
        if r.scheduledDays <= 0 {
            let minutes = max(1, Int((seconds / 60).rounded()))
            if minutes < 60 { return "\(minutes.fa) دقیقه" }
            let hours = max(1, Int((Double(minutes) / 60).rounded()))
            if hours < 24 { return "\(hours.fa) ساعت" }
            return "\(max(1, Int((Double(hours) / 24).rounded())).fa) روز"
        }
        let days = max(1, Int(r.scheduledDays.rounded()))
        if days < 30 { return "\(days.fa) روز" }
        if days < 365 { return "\(max(1, Int((Double(days) / 30).rounded())).fa) ماه" }
        return "\((Double(days) / 365).fa(fractionDigits: 1)) سال"
    }
}
