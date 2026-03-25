import SwiftUI
import SwiftData

struct MaintenanceChecklistView: View {
    @Bindable var vehicle: Vehicle
    @State private var newItemTitle = ""
    @State private var showAddItem = false
    @FocusState private var isAddFieldFocused: Bool
    @Environment(\.modelContext) private var context
    @Environment(\.appTheme) private var theme

    var pendingItems: [MaintenanceChecklistItem] {
        vehicle.safeChecklistItems.filter { !$0.isCompleted }.sorted { $0.createdDate > $1.createdDate }
    }

    var completedItems: [MaintenanceChecklistItem] {
        vehicle.safeChecklistItems.filter { $0.isCompleted }.sorted { ($0.completedDate ?? .now) > ($1.completedDate ?? .now) }
    }

    var body: some View {
        List {
            // Add item
            Section {
                HStack {
                    TextField("Add checklist item...", text: $newItemTitle)
                        .focused($isAddFieldFocused)
                        .textInputAutocapitalization(.sentences)
                        .onSubmit { addItem() }

                    Button {
                        addItem()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.wrenchAmber)
                    }
                    .disabled(newItemTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            // Empty state + Quick-add presets
            if vehicle.safeChecklistItems.isEmpty {
                Section {
                    VStack(spacing: 24) {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(theme.accent.opacity(0.1))
                                .frame(width: 100, height: 100)
                            Image(systemName: "checklist")
                                .font(.system(size: 40))
                                .foregroundStyle(theme.accent)
                                .symbolEffect(.pulse.wholeSymbol, options: .repeating.speed(0.5))
                        }
                        .accessibilityHidden(true)
                        VStack(spacing: 8) {
                            Text("No Checklist Items")
                                .font(.system(.title3, design: .rounded, weight: .bold))
                            Text("Add items to track your maintenance tasks.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        Button {
                            isAddFieldFocused = true
                        } label: {
                            Label("Add First Item", systemImage: "plus.circle.fill")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(theme.accent)
                        }
                        .pressable()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }

                Section {
                    ForEach(presetItems, id: \.self) { preset in
                        Button {
                            addPreset(preset)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "plus.circle")
                                    .font(.caption)
                                    .foregroundStyle(theme.accent)
                                Text(preset)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                            }
                        }
                        .pressable()
                    }
                } header: {
                    Text("Suggested Items")
                        .font(.system(.headline, design: .rounded))
                }
            }

            // Pending
            if !pendingItems.isEmpty {
                Section("To Do (\(pendingItems.count))") {
                    ForEach(pendingItems) { item in
                        checklistRow(item)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            context.delete(pendingItems[index])
                        }
                        DataManager.trySave(context)
                    }
                }
            }

            // Completed
            if !completedItems.isEmpty {
                Section("Completed (\(completedItems.count))") {
                    ForEach(completedItems) { item in
                        checklistRow(item)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            context.delete(completedItems[index])
                        }
                        DataManager.trySave(context)
                    }
                }
            }
        }
        .navigationTitle("Checklist")
    }

    private func checklistRow(_ item: MaintenanceChecklistItem) -> some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    item.isCompleted.toggle()
                    item.completedDate = item.isCompleted ? .now : nil
                    DataManager.trySave(context)
                }
                HapticManager.shared.light()
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isCompleted ? Color.wrenchGreen : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)

                if item.isCompleted, let completed = item.completedDate {
                    Text("Done \(completed, format: .dateTime.month(.abbreviated).day())")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private func addItem() {
        let title = newItemTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }

        let item = MaintenanceChecklistItem(title: title)
        item.vehicle = vehicle
        context.insert(item)
        DataManager.trySave(context)
        newItemTitle = ""
        HapticManager.shared.light()
    }

    private func addPreset(_ title: String) {
        let item = MaintenanceChecklistItem(title: title)
        item.vehicle = vehicle
        context.insert(item)
        DataManager.trySave(context)
        HapticManager.shared.light()
    }

    private var presetItems: [String] {
        [
            "Check tire pressure",
            "Check oil level",
            "Inspect brake pads",
            "Check all lights",
            "Top off windshield fluid",
            "Inspect wiper blades",
            "Check coolant level",
            "Rotate tires"
        ]
    }
}
