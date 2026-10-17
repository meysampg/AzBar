import SwiftUI

struct AboutView: View {
    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(PersianNumber.digits(version)) (\(PersianNumber.digits(build)))"
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: Theme.Spacing.s) {
                    Text("ازبر")
                        .font(.azDisplay)
                        .foregroundStyle(Theme.Palette.teal)
                    Text("حفظ شعر فارسی: حافظ، سعدی، خیام، صائب")
                        .font(.azMeta)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                    Text(verbatim: versionText)
                        .font(.azCaption)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.m)
                .listRowBackground(Color.clear)
                .accessibilityElement(children: .combine)
            }

            Section {
                Text("متن شعرها، معنی بیت‌ها و خوانش‌ها از گنجور (ganjoor.net) گرفته شده است. حقوق معنی‌ها و خوانش‌ها از آنِ گنجور و خوانندگان آن‌هاست.")
                if let url = URL(string: "https://ganjoor.net") {
                    Link(destination: url) {
                        Label("باز کردن گنجور", systemImage: "safari")
                    }
                }
            } header: {
                AzListHeader("منبع شعرها")
            }

            Section {
                if let url = URL(string: "https://github.com/meysampg/AzBar") {
                    Link(destination: url) {
                        Label("کد منبع در گیت‌هاب", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
                if let url = URL(string: "https://github.com/meysampg/AzBar/issues") {
                    Link(destination: url) {
                        Label("گزارش مشکل یا پیشنهاد", systemImage: "exclamationmark.bubble")
                    }
                }
                if let url = URL(string: "https://github.com/meysampg/AzBar/blob/main/PRIVACY.md") {
                    Link(destination: url) {
                        Label("سیاست حریم خصوصی", systemImage: "hand.raised")
                    }
                }
                LabeledContent("مجوز کد") {
                    Text(verbatim: "MIT")
                }
            } header: {
                AzListHeader("متن‌باز")
            }

            Section {
                Text("وزیرمتن، نوتو نسخ عربی، نوتو نستعلیق اردو — SIL OFL 1.1")
            } header: {
                AzListHeader("قلم‌ها")
            }

            Section {
                LabeledContent("نسخه") {
                    Text(verbatim: versionText)
                }
            } footer: {
                Text(verbatim: "© 2026 Meysam Pourganji")
                    .font(.azCaption)
                    .foregroundStyle(Theme.Palette.inkSecondary)
            }
        }
        .azList()
        .foregroundStyle(Theme.Palette.ink)
        .tint(Theme.Palette.teal)
        .navigationTitle("دربارهٔ ازبر")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    PreviewContainer {
        NavigationStack { AboutView() }
    }
}
