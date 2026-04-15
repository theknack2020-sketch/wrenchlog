import SwiftData
import SwiftUI
import TipKit

struct MaintenanceChecklistView: View {
    @Bindable var vehicle: Vehicle
    @State private var newItemTitle = ""
    @State private var showAddItem = false
    @State private var completionTrigger = false
    @FocusState private var isAddFieldFocused: Bool
    @Environment(\.modelContext) private var context
    @Environment(\.appTheme) private var theme
    @Environment(\.horizontalSizeClass) private var sizeClass

    var pendingItems: [MaintenanceChecklistItem] {
        vehicle.safeChecklistItems.filter { !$0.isCompleted }.sorted { $0.createdDate > $1.createdDate }
    }

    var completedItems: [MaintenanceChecklistItem] {
        vehicle.safeChecklistItems.filter(\.isCompleted).sorted { ($0.completedDate ?? .now) > ($1.completedDate ?? .now) }
    }

    var body: some View {
        List {
            Section {
                TipView(ChecklistTip())
                    .tipBackground(theme.accent.opacity(0.08))
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            // Add item
            Section {
                HStack {
                    TextField("Add checklist item...", text: $newItemTitle)
                        .focused($isAddFieldFocused)
                        .textInputAutocapitalization(.sentences)
                        .onSubmit { addItem() }
                        .accessibilityLabel("New checklist item")
                        .accessibilityIdentifier("checklistNewItem")

                    Button {
                        addItem()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(theme.accent)
                    }
                    .disabled(newItemTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Add checklist item")
                    .accessibilityHint("Adds the entered item to your checklist")
                }
            }

            // Empty state + Quick-add presets
            if vehicle.safeChecklistItems.isEmpty {
                ContentUnavailableView {
                    Label("No Checklist Items", systemImage: "checklist")
                } description: {
                    Text("Add items to track quick maintenance tasks.")
                } actions: {
                    Button {
                        isAddFieldFocused = true
                    } label: {
                        Label("Add First Item", systemImage: "plus.circle.fill")
                            .font(.subheadline.weight(.medium))
                    }
                    .pressable()
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

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
        .sensoryFeedback(.success, trigger: completionTrigger)
    }

    private func checklistRow(_ item: MaintenanceChecklistItem) -> some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6, blendDuration: 0.1)) {
                    item.isCompleted.toggle()
                    item.completedDate = item.isCompleted ? .now : nil
                    DataManager.trySave(context)
                    if item.isCompleted {
                        completionTrigger.toggle()
                    }
                }
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isCompleted ? Color.Status.success.shade500 : .secondary)
                    .symbolEffect(.bounce, value: item.isCompleted)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel(item.isCompleted ? "Mark \(item.title) as incomplete" : "Mark \(item.title) as complete")

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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title)\(item.isCompleted ? ", completed" : ", pending")")
        .accessibilityAddTraits(.isButton)
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
            "Rotate tires",
        ]
    }
}
