import UIKit

/// Centralized haptic feedback — one place for all tactile patterns.
@MainActor
final class HapticManager {
    static let shared = HapticManager()

    /// Whether haptics are enabled. Shares the same toggle as SoundManager.
    private var isEnabled: Bool {
        !UserDefaults.standard.bool(forKey: "wl_sounds_disabled")
    }

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    private init() {
        // Pre-warm so first tap is instant
        lightGenerator.prepare()
        mediumGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }

    // MARK: - Impact

    func light() {
        guard isEnabled else { return }
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
    }

    func medium() {
        guard isEnabled else { return }
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
    }

    func heavy() {
        guard isEnabled else { return }
        heavyGenerator.impactOccurred()
        heavyGenerator.prepare()
    }

    // MARK: - Notification

    func success() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    func warning() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }

    func error() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }

    // MARK: - Selection

    func selection() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    // MARK: - Compound Patterns

    /// Double-tap success pattern for milestone celebrations
    func celebrate() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
            heavyGenerator.impactOccurred(intensity: 0.8)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
                lightGenerator.impactOccurred()
                notificationGenerator.prepare()
            }
        }
    }

    /// Save confirmation — success + light finish
    func saveSuccess() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [self] in
            lightGenerator.impactOccurred()
            lightGenerator.prepare()
        }
    }

    /// Delete warning — warning + medium thud
    func deleteWarning() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.warning)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            mediumGenerator.impactOccurred(intensity: 0.7)
            mediumGenerator.prepare()
        }
    }

    /// Quick button tap — lighter than medium, snappier
    func buttonTap() {
        guard isEnabled else { return }
        mediumGenerator.impactOccurred(intensity: 0.5)
        mediumGenerator.prepare()
    }

    /// Section expand/collapse toggle
    func sectionToggle() {
        guard isEnabled else { return }
        lightGenerator.impactOccurred(intensity: 0.6)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { [self] in
            selectionGenerator.selectionChanged()
            selectionGenerator.prepare()
        }
    }

    /// Card press — medium + light double-pulse
    func cardPress() {
        guard isEnabled else { return }
        mediumGenerator.impactOccurred(intensity: 0.4)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [self] in
            lightGenerator.impactOccurred(intensity: 0.3)
            lightGenerator.prepare()
        }
    }

    /// Tab switch — crisp selection tick
    func tabSwitch() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [self] in
            lightGenerator.impactOccurred(intensity: 0.3)
            lightGenerator.prepare()
        }
    }

    /// Refresh pull — ramp up from light to medium
    func refreshPull() {
        guard isEnabled else { return }
        lightGenerator.impactOccurred(intensity: 0.4)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            mediumGenerator.impactOccurred(intensity: 0.6)
            mediumGenerator.prepare()
        }
    }

    /// Mileage update — ascending double tap
    func mileageUpdate() {
        guard isEnabled else { return }
        mediumGenerator.impactOccurred(intensity: 0.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [self] in
            notificationGenerator.notificationOccurred(.success)
            notificationGenerator.prepare()
        }
    }
}
