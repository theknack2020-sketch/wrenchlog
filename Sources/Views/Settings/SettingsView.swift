import SwiftUI
import SwiftData
import StoreKit
import UniformTypeIdentifiers
import UserNotifications

struct SettingsView: View {
    @State private var distanceUnit = UserSettings.shared.distanceUnit
    @State private var volumeUnit = UserSettings.shared.volumeUnit
    @State private var efficiencyUnit = UserSettings.shared.efficiencyUnit
    @State private var currency = UserSettings.shared.currency
    @State private var selectedTheme = ThemeManager.shared.current
    @State private var showPro = false
    @State private var showResetConfirm = false
    @State private var showResetFinal = false
    @State private var showImportPicker = false
    @State private var showExportShare = false
    @State private var exportURLs: [URL] = []
    @State private var importResult: String?
    @State private var showImportResult = false
    @State private var remindersEnabled = ReminderStore.remindersEnabled
    @State private var mileageNudge = ReminderStore.mileageNudgeEnabled
    @State private var calendarSync = CalendarStore.calendarSyncEnabled
    @State private var calendarStatus: String = ""
    @State private var notificationStatus: String = "Checking..."
    @State private var showErrorAlert = false
    @State private var errorAlertMessage = ""
    @AppStorage("wl_onboarding_complete") private var onboardingComplete = true
    @Environment(\.modelContext) private var context
    @Environment(\.requestReview) private var requestReview
    @Environment(\.appTheme) private var theme
    private let store = StoreManager.shared

    var body: some View {
        Form {
            // MARK: - Header Banner
            Section {
                HStack(spacing: 10) {
                    Image(systemName: "gearshape.2.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Settings")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Customize your experience")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: theme.headerGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: theme.accent.opacity(0.25), radius: 8, x: 0, y: 4)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)

            // MARK: - Units
            Section {
                Picker("Distance", selection: $distanceUnit) {
                    Text("Miles").tag(DistanceUnit.miles)
                    Text("Kilometers").tag(DistanceUnit.km)
                }
                .accessibilityLabel("Distance unit")
                .onChange(of: distanceUnit) { _, val in
                    UserSettings.shared.distanceUnit = val
                }

                Picker("Volume", selection: $volumeUnit) {
                    Text("Gallons").tag(VolumeUnit.gallons)
                    Text("Liters").tag(VolumeUnit.liters)
                }
                .accessibilityLabel("Volume unit")
                .onChange(of: volumeUnit) { _, val in
                    UserSettings.shared.volumeUnit = val
                }

                Picker("Fuel Efficiency", selection: $efficiencyUnit) {
                    Text("MPG").tag(EfficiencyUnit.mpg)
                    Text("L/100km").tag(EfficiencyUnit.l100km)
                }
                .accessibilityLabel("Fuel efficiency unit")
                .onChange(of: efficiencyUnit) { _, val in
                    UserSettings.shared.efficiencyUnit = val
                }

                Picker("Currency", selection: $currency) {
                    Text("$ USD").tag(Currency.usd)
                    Text("€ EUR").tag(Currency.eur)
                    Text("£ GBP").tag(Currency.gbp)
                    Text("₺ TRY").tag(Currency.try_)
                }
                .accessibilityLabel("Currency for costs")
                .onChange(of: currency) { _, val in
                    UserSettings.shared.currency = val
                }
            } header: {
                Text("Units")
                    .font(.system(.headline, design: .rounded))
            }

            // MARK: - Appearance
            appearanceSection

            // MARK: - Sound & Haptics
            Section {
                Toggle("Sound & Haptics", isOn: Binding(
                    get: { !UserDefaults.standard.bool(forKey: "wl_sounds_disabled") },
                    set: { UserDefaults.standard.set(!$0, forKey: "wl_sounds_disabled") }
                ))
                .accessibilityLabel("Sound and haptics")
                .accessibilityHint("Toggle sound effects and haptic feedback throughout the app")
            } header: {
                Text("Sound & Haptics")
            } footer: {
                Text("Controls system sounds and haptic feedback for actions like saving, deleting, and navigation.")
            }

            // MARK: - Notifications
            Section {
                Toggle("Service Reminders", isOn: $remindersEnabled)
                    .accessibilityLabel("Service reminders")
                    .accessibilityHint("Toggle to enable or disable service due reminders")
                    .onChange(of: remindersEnabled) { _, val in
                        ReminderStore.remindersEnabled = val
                        if val {
                            Task {
                                let granted = await ReminderManager.shared.requestAuthorization()
                                if granted {
                                    let vehicles = (try? context.fetch(FetchDescriptor<Vehicle>())) ?? []
                                    await ReminderManager.shared.scheduleReminders(for: vehicles)
                                }
                                await updateNotificationStatus()
                            }
                        } else {
                            ReminderManager.shared.cancelAll()
                        }
                    }

                Toggle("Weekly Mileage Nudge", isOn: $mileageNudge)
                    .accessibilityLabel("Weekly mileage reminder")
                    .accessibilityHint("Get a weekly reminder to update your odometer")
                    .onChange(of: mileageNudge) { _, val in
                        ReminderStore.mileageNudgeEnabled = val
                    }

                HStack {
                    Text("Notification Status")
                    Spacer()
                    Text(notificationStatus)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if notificationStatus == "Denied" {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("Open Settings to enable notifications")
                                .font(.subheadline)
                        }
                    }
                }
            } header: {
                Text("Notifications")
            } footer: {
                Text("Reminders notify you when services are due based on time intervals, mileage, and your driving pace. Enable notifications for the best experience.")
            }

            // MARK: - Calendar Sync
            Section {
                Toggle("Add Services to Calendar", isOn: $calendarSync)
                    .accessibilityLabel("Calendar sync")
                    .accessibilityHint("Automatically adds service records to your iOS Calendar")
                    .onChange(of: calendarSync) { _, enabled in
                        CalendarStore.calendarSyncEnabled = enabled
                        if enabled {
                            Task {
                                let granted = await CalendarService.shared.requestAccess()
                                if granted {
                                    calendarStatus = "Connected"
                                    // Sync existing records
                                    let vehicles = (try? context.fetch(FetchDescriptor<Vehicle>())) ?? []
                                    let count = CalendarService.shared.syncAllRecords(vehicles: vehicles)
                                    if count > 0 {
                                        try? DataManager.save(context)
                                    }
                                } else {
                                    calendarStatus = "Denied"
                                    calendarSync = false
                                    CalendarStore.calendarSyncEnabled = false
                                }
                            }
                        }
                    }

                if calendarSync {
                    HStack {
                        Text("Calendar Status")
                        Spacer()
                        Text(calendarStatus)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if calendarStatus == "Denied" {
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("Open Settings to enable Calendar access")
                                    .font(.subheadline)
                            }
                        }
                    }

                    Button {
                        let vehicles = (try? context.fetch(FetchDescriptor<Vehicle>())) ?? []
                        let count = CalendarService.shared.syncAllRecords(vehicles: vehicles)
                        if count > 0 {
                            try? DataManager.save(context)
                            HapticManager.shared.success()
                        }
                        calendarStatus = "Synced (\(count) new)"
                    } label: {
                        Label("Sync All Records Now", systemImage: "arrow.triangle.2.circlepath")
                            .font(.subheadline)
                    }
                }
            } header: {
                Text("Calendar")
            } footer: {
                Text("New service records are automatically added to a \"WrenchLog\" calendar in your iOS Calendar app.")
            }

            // MARK: - iCloud Sync
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "cloud.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("iCloud Sync")
                            .font(.subheadline.weight(.medium))
                        Text("Enabled")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                Text("Your data syncs automatically across all your devices via iCloud.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("iCloud Sync")
            } footer: {
                Text("Make sure iCloud is enabled in Settings → Apple ID → iCloud for seamless sync.")
            }

            // MARK: - Premium
            Section {
                if store.isPro {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                LinearGradient(
                                    colors: [.green, Color(red: 0.15, green: 0.70, blue: 0.35)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("WrenchLog Pro")
                                .font(.subheadline.weight(.semibold))
                            Text("All features unlocked")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("Active")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    colors: [.green, Color(red: 0.15, green: 0.70, blue: 0.35)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                } else {
                    Button {
                        showPro = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "crown.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Upgrade to Pro")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text("Unlimited vehicles, photos, PDF export")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.91, green: 0.64, blue: 0.09), Color(red: 0.85, green: 0.55, blue: 0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: Color(red: 0.91, green: 0.64, blue: 0.09).opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .pressable()
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }
            } header: {
                Text("Premium")
                    .font(.system(.headline, design: .rounded))
            }

            // MARK: - Data Management
            dataManagementSection

            // MARK: - Share & Rate
            Section {
                // Share App
                ShareLink(
                    item: URL(string: "https://apps.apple.com/app/wrenchlog/id6743597962")!,
                    subject: Text("Check out WrenchLog"),
                    message: Text("I use WrenchLog to track my vehicle maintenance. Keeps everything organized — no account needed.")
                ) {
                    Label("Share WrenchLog", systemImage: "square.and.arrow.up")
                }
                .accessibilityLabel("Share WrenchLog with friends")

                // Rate Us
                Button {
                    requestReview()
                } label: {
                    Label("Rate on App Store", systemImage: "star.fill")
                }
                .pressable()
                .accessibilityLabel("Rate WrenchLog on the App Store")
            } header: {
                Text("Spread the Word")
                    .font(.system(.headline, design: .rounded))
            }

            // MARK: - About
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }

                // Contact Support
                Link(destination: URL(string: "mailto:theknack2020@gmail.com?subject=WrenchLog%20Support%20(\(appVersion))")!) {
                    Label("Contact Support", systemImage: "envelope")
                }

                Link("Privacy Policy", destination: URL(string: "https://theknack2020-sketch.github.io/wrenchlog/privacy/")!)
                Link("Terms of Use", destination: URL(string: "https://theknack2020-sketch.github.io/wrenchlog/terms/")!)

                Button {
                    onboardingComplete = false
                    HapticManager.shared.success()
                } label: {
                    Label("Replay Onboarding", systemImage: "arrow.counterclockwise")
                }
                .accessibilityLabel("Replay onboarding")
                .accessibilityHint("Shows the welcome screens again on next app launch")
            } header: {
                Text("About")
                    .font(.system(.headline, design: .rounded))
            } footer: {
                if !onboardingComplete {
                    Text("Onboarding will show on next app launch.")
                }
            }

            // MARK: - More Apps
            Section {
                Link(destination: URL(string: "https://apps.apple.com/app/lumifaste/id6760971357")!) {
                    HStack(spacing: 12) {
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(.purple)
                            .frame(width: 24)
                        VStack(alignment: .leading) {
                            Text("Lumifaste").font(.subheadline.weight(.medium))
                            Text("Intermittent Fasting Tracker").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("More Apps")
                    .font(.system(.headline, design: .rounded))
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            Task {
                await updateNotificationStatus()
                updateCalendarStatus()
            }
        }
        .sheet(isPresented: $showPro) {
            ProUpgradeView()
        }
        .sheet(isPresented: $showExportShare) {
            if !exportURLs.isEmpty {
                ShareSheetView(items: exportURLs)
            }
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .alert("Import Complete", isPresented: $showImportResult) {
            Button("OK") {}
        } message: {
            Text(importResult ?? "")
        }
        // Two-step reset confirmation
        .alert("Reset All Data?", isPresented: $showResetConfirm) {
            Button("Continue", role: .destructive) {
                showResetFinal = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete ALL vehicles, service records, and fuel logs. This action cannot be undone.")
        }
        .alert("Are you absolutely sure?", isPresented: $showResetFinal) {
            Button("Delete Everything", role: .destructive) {
                resetAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Last chance. All your data will be permanently erased.")
        }
        .alert("Something Went Wrong", isPresented: $showErrorAlert) {
            Button("OK") {}
        } message: {
            Text(errorAlertMessage)
        }
    }

    // MARK: - Data Management Section (extracted for type-checker)

    private var dataManagementSection: some View {
        Section {
            // Export CSV — Pro only
            Button {
                if store.isPro {
                    exportData()
                } else {
                    showPro = true
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(theme.accent, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    Text("Export Data (CSV)")
                    if !store.isPro {
                        Spacer()
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundStyle(theme.accent)
                    }
                }
            }
            .pressable()
            .accessibilityIdentifier("settingsExportCSV")
            .accessibilityLabel(store.isPro ? "Export all data as CSV files" : "Export data, Pro feature")

            // Import CSV
            Button {
                showImportPicker = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(theme.accent, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    Text("Import Data (CSV)")
                }
            }
            .pressable()
            .accessibilityLabel("Import data from CSV file")

            // Reset All Data
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "trash")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(.red, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    Text("Reset All Data")
                        .foregroundStyle(.red)
                }
            }
            .pressable()
            .accessibilityLabel("Reset all data")
            .accessibilityHint("Permanently deletes all vehicles and records")
        } header: {
            Text("Data")
        }
    }

    // MARK: - Appearance Section (extracted for type-checker)

    private var appearanceSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Color Theme")
                    .font(.subheadline)

                HStack(spacing: 12) {
                    ForEach(AppTheme.allCases) { appTheme in
                        let isFreeTheme = appTheme == .defaultAmber || appTheme == .darkMono
                        let isLocked = !store.isPro && !isFreeTheme
                        Button {
                            if isLocked {
                                showPro = true
                            } else {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    selectedTheme = appTheme
                                    ThemeManager.shared.current = appTheme
                                }
                                HapticManager.shared.selection()
                            }
                        } label: {
                            VStack(spacing: 6) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(appTheme.accent.opacity(isLocked ? 0.08 : 0.15))
                                        .frame(width: 56, height: 56)
                                    if isLocked {
                                        Image(systemName: "lock.fill")
                                            .font(.body)
                                            .foregroundStyle(appTheme.accent.opacity(0.4))
                                    } else {
                                        Image(systemName: appTheme.icon)
                                            .font(.title3)
                                            .foregroundStyle(appTheme.accent)
                                    }
                                }
                                .overlay {
                                    if selectedTheme == appTheme {
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(appTheme.accent, lineWidth: 2.5)
                                            .frame(width: 56, height: 56)
                                    }
                                }

                                Text(appTheme.rawValue)
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(selectedTheme == appTheme ? AnyShapeStyle(appTheme.accent) : isLocked ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.secondary))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(appTheme.rawValue) theme\(isLocked ? ", Pro only" : "")")
                        .accessibilityAddTraits(selectedTheme == appTheme ? .isSelected : [])
                    }
                }
                .padding(10)
                .glassBackground(cornerRadius: 14)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Appearance")
        }
    }

    // MARK: - App Version (dynamic from bundle)

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: - Export

    private func exportData() {
        let vehicles = (try? context.fetch(FetchDescriptor<Vehicle>())) ?? []
        guard !vehicles.isEmpty else {
            importResult = "No data to export."
            showImportResult = true
            return
        }

        let (serviceCSV, fuelCSV) = DataExportImportService.exportCSV(vehicles: vehicles, settings: UserSettings.shared)

        var urls: [URL] = []
        if let serviceURL = DataExportImportService.writeToTempFile(serviceCSV, fileName: "WrenchLog_Services.csv") {
            urls.append(serviceURL)
        }
        if let fuelURL = DataExportImportService.writeToTempFile(fuelCSV, fileName: "WrenchLog_Fuel.csv") {
            urls.append(fuelURL)
        }

        if !urls.isEmpty {
            exportURLs = urls
            showExportShare = true
            HapticManager.shared.success()
            SoundManager.playSaveSuccess()
        } else {
            errorAlertMessage = "Unable to create export files. Please check available storage and try again."
            showErrorAlert = true
            HapticManager.shared.error()
            SoundManager.playError()
        }
    }

    // MARK: - Import

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                importResult = "Unable to access the selected file."
                showImportResult = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            guard let data = try? Data(contentsOf: url) else {
                importResult = "Unable to read the selected file."
                showImportResult = true
                return
            }

            if let counts = DataExportImportService.importServiceCSV(data: data, context: context) {
                importResult = "Imported \(counts.recordCount) service record\(counts.recordCount == 1 ? "" : "s") across \(counts.vehicleCount) vehicle\(counts.vehicleCount == 1 ? "" : "s")."
                HapticManager.shared.success()
            } else {
                importResult = "Could not parse CSV. Ensure it has columns: Vehicle, Make, Model, Year, Service Type, Service Date, Mileage, Cost."
                HapticManager.shared.error()
            }
            showImportResult = true

        case .failure(let error):
            importResult = "Import failed: \(error.localizedDescription)"
            showImportResult = true
        }
    }

    // MARK: - Reset

    private func resetAllData() {
        do {
            let vehicles = try DataManager.fetch(FetchDescriptor<Vehicle>(), from: context)
            for vehicle in vehicles {
                for record in vehicle.safeServiceRecords {
                    ServicePhotoManager.shared.deletePhotos(for: record.photoFileNames)
                }
                context.delete(vehicle)
            }

            // Delete any orphaned records/logs
            let records = try DataManager.fetch(FetchDescriptor<ServiceRecord>(), from: context)
            for record in records { context.delete(record) }

            let fuelLogs = try DataManager.fetch(FetchDescriptor<FuelLog>(), from: context)
            for log in fuelLogs { context.delete(log) }

            let checklistItems = try DataManager.fetch(FetchDescriptor<MaintenanceChecklistItem>(), from: context)
            for item in checklistItems { context.delete(item) }

            try DataManager.save(context)

            // Cancel reminders
            ReminderManager.shared.cancelAll()

            HapticManager.shared.warning()
            SoundManager.playDelete()
        } catch {
            errorAlertMessage = "Unable to reset your data. Please restart the app and try again."
            showErrorAlert = true
            HapticManager.shared.error()
            SoundManager.playError()
        }
    }

    // MARK: - Notification Status

    private func updateNotificationStatus() async {
        await ReminderManager.shared.refreshAuthorizationStatus()
        let status = ReminderManager.shared.authorizationStatus
        switch status {
        case .authorized: notificationStatus = "Enabled"
        case .denied: notificationStatus = "Denied"
        case .provisional: notificationStatus = "Provisional"
        case .notDetermined: notificationStatus = "Not Asked"
        case .ephemeral: notificationStatus = "Ephemeral"
        @unknown default: notificationStatus = "Unknown"
        }
    }

    // MARK: - Calendar Status

    private func updateCalendarStatus() {
        guard calendarSync else { calendarStatus = ""; return }
        switch CalendarService.shared.authorizationStatus {
        case .authorized: calendarStatus = "Connected"
        case .denied: calendarStatus = "Denied"
        case .restricted: calendarStatus = "Restricted"
        case .notDetermined: calendarStatus = "Not Asked"
        }
    }
}
