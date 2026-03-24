import AudioToolbox

/// System sound IDs for feedback events.
/// Uses AudioServices — no AVFoundation overhead, respects silent mode on supported IDs.
enum SoundManager {
    /// Whether sounds and haptics are enabled. Reads from UserDefaults to stay in sync with SettingsView toggle.
    static var isEnabled: Bool {
        !UserDefaults.standard.bool(forKey: "wl_sounds_disabled")
    }

    /// Gentle "tink" — save confirmation (system keyboard sound variant)
    static func playSaveSuccess() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1057)
    }

    /// Short percussive delete sound
    static func playDelete() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1306)
    }

    /// Low error tone
    static func playError() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1053)
    }

    /// Celebratory ascending tone for milestones
    static func playCelebration() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1025)
    }

    /// Smooth whoosh for transitions and navigation
    static func playTransition() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1104)
    }
}
