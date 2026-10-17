import SwiftUI

struct AzEmptyState: View {
    let systemImage: String
    let title: String
    var message: String?
    var actionTitle: String?
    var action: (() -> Void)?

    init(_ systemImage: String, _ title: String, _ message: String? = nil,
         _ actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    init(systemImage: String, title: String, message: String? = nil,
         actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.init(systemImage, title, message, actionTitle, action: action)
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.l) {
            Circle()
                .fill(Theme.Palette.tealSoft)
                .frame(width: 96, height: 96)
                .overlay {
                    Image(systemName: systemImage)
                        .font(.system(size: 40, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Theme.Palette.teal)
                }
                .accessibilityHidden(true)
            VStack(spacing: Theme.Spacing.s) {
                Text(verbatim: title)
                    .font(.app(.title3, weight: .bold))
                    .foregroundStyle(Theme.Palette.ink)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                if let message {
                    Text(verbatim: message)
                        .font(.azMeta)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            if let actionTitle, let action {
                Button(action: action) { Text(verbatim: actionTitle) }
                    .buttonStyle(.azSecondary)
                    .frame(maxWidth: 260)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xl)
        .accessibilityElement(children: .contain)
    }
}

struct AzLoadingView: View {
    var text: String

    init(_ text: String = "در حال بارگذاری…") { self.text = text }

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            ProgressView().tint(Theme.Palette.teal)
            Text(verbatim: text)
                .font(.azCaption)
                .foregroundStyle(Theme.Palette.inkSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xl)
        .accessibilityElement(children: .combine)
    }
}

struct AzErrorView: View {
    var retry: () -> Void

    init(retry: @escaping () -> Void) { self.retry = retry }

    var body: some View {
        AzEmptyState("wifi.slash", "اتصال برقرار نشد",
                     "اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.", "تلاش دوباره", action: retry)
    }
}

#Preview("Empty") {
    AzEmptyState("text.book.closed", "هنوز شعری برای حفظ برنگزیده‌اید",
                 "از کتابخانه شعری برگزینید و «حفظ کن» را بزنید", "رفتن به کتابخانه") {}
        .azScreenBackground()
        .persianRoot()
}

#Preview("Loading and error") {
    VStack {
        AzLoadingView()
        AzErrorView {}
    }
    .azScreenBackground()
    .persianRoot()
}
