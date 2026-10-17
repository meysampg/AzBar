import Testing
@testable import AzBar

struct PersianNumberTests {
    @Test func convertsDigits() {
        #expect(PersianNumber.string(1405) == "۱۴۰۵")
        #expect(5.fa == "۵")
        #expect(PersianNumber.digits("a12") == "a۱۲")
    }

    @Test func groupsLargeNumbers() {
        #expect(PersianNumber.string(12345) == "۱۲٬۳۴۵")
        #expect(PersianNumber.string(9999) == "۹۹۹۹")
    }

    @Test func formatsDecimals() {
        #expect(1.25.fa(fractionDigits: 1) == "۱٫۲" || 1.25.fa(fractionDigits: 1) == "۱٫۳")
    }
}
