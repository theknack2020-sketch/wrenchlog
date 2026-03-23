import AudioToolbox

/// System sound IDs for feedback events.
/// Uses AudioServices — no AVFoundation overhead, respects silent mode on supported IDs.
enum SoundManager {
    /// Gentle "tink" — save confirmation (system keyboard sound variant)
    static func playSaveSuccess() {
        AudioServicesPlaySystemSound(1057)
    }

    /// Short percussive delete sound
    static func playDelete() {
        AudioServicesPlaySystemSound(1306)
    }

    /// Low error tone
    static func playError() {
        AudioServicesPlaySystemSound(1053)
    }

    /// Celebratory ascending tone for milestones
    static func playCelebration() {
        AudioServicesPlaySystemSound(1025)
    }
}
