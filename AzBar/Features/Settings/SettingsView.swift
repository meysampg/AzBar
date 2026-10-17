import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(AppSettings.self) private var settings
    @Environment(ProgressStore.self) private var progress
    @Environment(\.contentRepository) private var content
    @Environment(\.scenePhase) private var scenePhase

    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var reciters: [String] = []

    var body: some View {
        @Bindable var settings = settings
        Form {
            fontSection(settings: $settings)
            displaySection(settings: $settings)
            remindersSection(settings: $settings)
            memorizationSection(settings: $settings)
            motivationSection(settings: $settings)
            reciterSection(settings: $settings)
            Section {
                NavigationLink("دربارهٔ ازبر") { AboutView() }
            } header: {
                Text("دربارهٔ برنامه").font(.app(.footnote))
            }
        }
        .navigationTitle("تنظیمات")
        .task {
            reciters = await content.recitationArtists(poetId: 2)
            await refreshStatus()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await refreshStatus() } }
        }
    }

    // MARK: Font

    private func fontSection(settings: Bindable<AppSettings>) -> some View {
        Section {
            Picker("قلم", selection: settings.poemFont) {
                ForEach(PoemFont.allCases) { font in
                    Text(font.title)
                        .font(.poem(font, size: 18))
                        .tag(font)
                }
            }
            .pickerStyle(.inline)

            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                HStack {
                    Text("اندازهٔ قلم")
                    Spacer()
                    Text(self.settings.poemFontSize.fa(fractionDigits: 0))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: settings.poemFontSize, in: 16...36, step: 1) {
                    Text("اندازهٔ قلم")
                } minimumValueLabel: {
                    Text("آ").font(.app(.footnote))
                } maximumValueLabel: {
                    Text("آ").font(.app(.title3))
                }
                .accessibilityValue(self.settings.poemFontSize.fa(fractionDigits: 0))
            }

            if let couplet = PreviewFixtures.samplePoem.couplets.first {
                CoupletView(couplet: couplet, layout: .stacked, showMeaning: false) {
                    self.settings.showDiacritics ? $0 : PersianText.removingDiacritics($0)
                }
                .listRowInsets(EdgeInsets(top: Theme.Spacing.s, leading: Theme.Spacing.m,
                                          bottom: Theme.Spacing.s, trailing: Theme.Spacing.m))
                .accessibilityLabel("پیش‌نمایش قلم")
            }
        } header: {
            Text("قلم شعر").font(.app(.footnote))
        }
    }

    // MARK: Display

    private func displaySection(settings: Bindable<AppSettings>) -> some View {
        Section {
            Toggle("نمایش معنی بیت‌ها", isOn: settings.showMeaning)
            Toggle("نمایش اعراب", isOn: settings.showDiacritics)
        } header: {
            Text("نمایش").font(.app(.footnote))
        }
    }

    // MARK: Reminders

    private func remindersSection(settings: Bindable<AppSettings>) -> some View {
        Section {
            Toggle("یادآوری روزانهٔ مرور", isOn: Binding(
                get: { self.settings.remindersEnabled },
                set: { setReminders($0) }
            ))
            if self.settings.remindersEnabled {
                DatePicker("ساعت یادآوری", selection: reminderTime, displayedComponents: .hourAndMinute)
            }
        } header: {
            Text("یادآوری").font(.app(.footnote))
        } footer: {
            if notificationStatus == .denied {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("اجازهٔ اعلان داده نشده است")
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        Link("باز کردن تنظیمات", destination: url)
                    }
                }
                .font(.app(.footnote))
            }
        }
        .sensoryFeedback(.selection, trigger: self.settings.remindersEnabled)
    }

    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: DateComponents(hour: settings.reminderHour, minute: settings.reminderMinute))
                    ?? .now
            },
            set: { newValue in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                settings.reminderHour = parts.hour ?? 20
                settings.reminderMinute = parts.minute ?? 0
                Task { await reschedule() }
            }
        )
    }

    private func setReminders(_ enabled: Bool) {
        if !enabled {
            settings.remindersEnabled = false
            Task { await reschedule() }
            return
        }
        Task {
            let granted = await model.reminders.requestAuthorization()
            settings.remindersEnabled = granted
            await refreshStatus()
            await reschedule()
        }
    }

    private func reschedule() async {
        await model.reminders.reschedule(
            enabled: settings.remindersEnabled,
            hour: settings.reminderHour,
            minute: settings.reminderMinute,
            store: progress
        )
    }

    private func refreshStatus() async {
        notificationStatus = await model.reminders.authorizationStatus()
        if notificationStatus == .denied, settings.remindersEnabled {
            settings.remindersEnabled = false
        }
    }

    // MARK: Memorization

    private func memorizationSection(settings: Bindable<AppSettings>) -> some View {
        Section {
            Stepper("بیت‌های تازه در هر جلسه: \(self.settings.newCoupletsPerSession.fa)",
                    value: settings.newCoupletsPerSession, in: 1...5)
            Picker("هدف یادسپاری", selection: settings.desiredRetention) {
                ForEach([0.85, 0.9, 0.95], id: \.self) { value in
                    Text("\(Int(value * 100).fa)٪").tag(value)
                }
            }
            Stepper("سقف مرور روزانه: \(self.settings.dailyReviewLimit.fa)",
                    value: settings.dailyReviewLimit, in: 20...500, step: 10)
        } header: {
            Text("حفظ").font(.app(.footnote))
        } footer: {
            Text("هدف یادسپاری بالاتر یعنی مرورهای نزدیک‌تر و بار روزانهٔ بیشتر.")
                .font(.app(.footnote))
        }
    }

    // MARK: Motivation

    private func motivationSection(settings: Bindable<AppSettings>) -> some View {
        Section {
            Picker("هدف روزانه", selection: settings.dailyXPGoal) {
                ForEach(DailyGoal.options, id: \.self) { goal in
                    Text("\(goal.fa) امتیاز · \(DailyGoalText.title(goal))").tag(goal)
                }
            }
            Toggle("صداها", isOn: settings.soundsEnabled)
            Toggle("تمرین‌های تعاملی", isOn: settings.exercisesEnabled)
        } header: {
            Text("انگیزه").font(.app(.footnote))
        } footer: {
            Text("واژه‌چینی و انتخاب واژه در درس‌ها").font(.app(.footnote))
        }
    }

    // MARK: Reciter

    private func reciterSection(settings: Bindable<AppSettings>) -> some View {
        let selected = self.settings.preferredReciter
        let options = (selected.map { reciters.contains($0) ? reciters : [$0] + reciters }) ?? reciters
        return Section {
            Picker("خوانندهٔ ترجیحی", selection: settings.preferredReciter) {
                Text("خودکار").tag(String?.none)
                ForEach(options, id: \.self) { artist in
                    Text(verbatim: artist).tag(String?.some(artist))
                }
            }
        } header: {
            Text("خوانش").font(.app(.footnote))
        }
    }
}

#Preview {
    PreviewContainer {
        NavigationStack { SettingsView() }
    }
}
