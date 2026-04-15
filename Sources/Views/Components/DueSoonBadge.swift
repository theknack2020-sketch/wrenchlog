import SwiftUI

// MARK: - Due Soon Badge

/// Reusable badge showing service urgency status: Overdue, Due Now, Due Soon, or On Track.
/// Color-coded (red/amber/orange/green) with matching icon and label.
struct DueSoonBadge: View {
    let urgency: ReminderUrgency
    let compact: Bool

    init(urgency: ReminderUrgency, compact: Bool = false) {
        self.urgency = urgency
        self.compact = compact
    }

    private var color: Color {
        switch urgency {
        case .overdue: Color.Status.error.shade500
        case .due: Color.Status.warning.shade600
        case .dueSoon: Color.Status.warning.shade400
        case .ok: Color.Status.success.shade500
        }
    }

    private var icon: String {
        switch urgency {
        case .overdue: "exclamationmark.triangle.fill"
        case .due: "wrench.fill"
        case .dueSoon: "clock.fill"
        case .ok: "checkmark.circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption2)
            if !compact {
                Text(urgency.label)
                    .font(.caption2.weight(.semibold))
            }
        }
        .foregroundStyle(color)
        .padding(.horizontal, compact ? 5 : 7)
        .padding(.vertical, 3)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: color.opacity(0.15), radius: 2, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Service status: \(urgency.label)")
    }
}

// MARK: - Due Soon Badge with Detail

/// Extended badge variant that includes the service name and due text.
/// Use in dashboard contexts where more detail is helpful.
struct DueSoonDetailBadge: View {
    let serviceType: String
    let urgency: ReminderUrgency
    let displayDue: String

    private var color: Color {
        switch urgency {
        case .overdue: Color.Status.error.shade500
        case .due: Color.Status.warning.shade600
        case .dueSoon: Color.Status.warning.shade400
        case .ok: Color.Status.success.shade500
        }
    }

    private var icon: String {
        switch urgency {
        case .overdue: "exclamationmark.triangle.fill"
        case .due: "wrench.fill"
        case .dueSoon: "clock.fill"
        case .ok: "checkmark.circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 0) {
                Text(serviceType)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.primary)
                if !displayDue.isEmpty {
                    Text(displayDue)
                        .font(.caption2)
                        .foregroundStyle(color)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .shadow(color: color.opacity(0.15), radius: 2, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(serviceType): \(urgency.label). \(displayDue)")
    }
}
