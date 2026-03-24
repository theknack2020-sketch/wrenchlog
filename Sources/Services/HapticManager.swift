import UIKit

/// Centralized haptic feedback — one place for all tactile patterns.
@MainActor
final class HapticManager {
    static let shared = HapticManager()

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
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
    }

    func medium() {
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
    }

    func heavy() {
        heavyGenerator.impactOccurred()
        heavyGenerator.prepare()
    }

    // MARK: - Notification

    func success() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    func warning() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }

    func error() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }

    // MARK: - Selection

    func selection() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    // MARK: - Compound Patterns

    /// Double-tap success pattern for milestone celebrations
    func celebrate() {
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
        notificationGenerator.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [self] in
            lightGenerator.impactOccurred()
            lightGenerator.prepare()
        }
    }

    /// Delete warning — warning + medium thud
    func deleteWarning() {
        notificationGenerator.notificationOccurred(.warning)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            mediumGenerator.impactOccurred(intensity: 0.7)
            mediumGenerator.prepare()
        }
    }

    /// Quick button tap — lighter than medium, snappier
    func buttonTap() {
        mediumGenerator.impactOccurred(intensity: 0.5)
        mediumGenerator.prepare()
    }

    /// Section expand/collapse toggle
    func sectionToggle() {
        lightGenerator.impactOccurred(intensity: 0.6)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { [self] in
            selectionGenerator.selectionChanged()
            selectionGenerator.prepare()
        }
    }

    /// Card press — medium + light double-pulse
    func cardPress() {
        mediumGenerator.impactOccurred(intensity: 0.4)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [self] in
            lightGenerator.impactOccurred(intensity: 0.3)
            lightGenerator.prepare()
        }
    }

    /// Tab switch — crisp selection tick
    func tabSwitch() {
        selectionGenerator.selectionChanged()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [self] in
            lightGenerator.impactOccurred(intensity: 0.3)
            lightGenerator.prepare()
        }
    }

    /// Refresh pull — ramp up from light to medium
    func refreshPull() {
        lightGenerator.impactOccurred(intensity: 0.4)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            mediumGenerator.impactOccurred(intensity: 0.6)
            mediumGenerator.prepare()
        }
    }

    /// Mileage update — ascending double tap
    func mileageUpdate() {
        mediumGenerator.impactOccurred(intensity: 0.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [self] in
            notificationGenerator.notificationOccurred(.success)
            notificationGenerator.prepare()
        }
    }
}
