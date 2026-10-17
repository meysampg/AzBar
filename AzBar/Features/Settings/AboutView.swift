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
                    Image(systemName: "text.book.closed.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                    Text("از بر").font(.app(.title))
                    Text("حفظ شعر فارسی، آغاز با حافظ")
                        .font(.app(.subheadline))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.m)
                .listRowBackground(Color.clear)
                .accessibilityElement(children: .combine)
            }

            Section {
                Text("متن، معنی و خوانش‌ها از گنجور (ganjoor.net)")
                if let url = URL(string: "https://ganjoor.net") {
                    Link(destination: url) {
                        Label("باز کردن گنجور", systemImage: "safari")
                    }
                }
            } header: {
                Text("منبع شعرها").font(.app(.footnote))
            }

            Section {
                Text("وزیرمتن، نوتو نسخ عربی، نوتو نستعلیق اردو — SIL OFL 1.1")
            } header: {
                Text("قلم‌ها").font(.app(.footnote))
            }

            Section {
                LabeledContent("نسخه") {
                    Text(verbatim: versionText)
                }
            }
        }
        .navigationTitle("دربارهٔ از بر")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    PreviewContainer {
        NavigationStack { AboutView() }
    }
}
