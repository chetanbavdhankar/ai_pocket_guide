// SFXManager.swift — AI Pocket Arena
// Play subtle sound effects for correct/incorrect answers, streak, level up. respects user settings.

import Foundation
import AudioToolbox

@MainActor
final class SFXManager {
    static let shared = SFXManager()
    
    private var isEnabled = true
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
    
    func correct() {
        guard isEnabled else { return }
        // System Sound ID 1054: Hero sound/success
        AudioServicesPlaySystemSound(1054)
    }
    
    func incorrect() {
        guard isEnabled else { return }
        // System Sound ID 1053: Error beep
        AudioServicesPlaySystemSound(1053)
    }
    
    func levelUp() {
        guard isEnabled else { return }
        // System Sound ID 1025: Achievement chime
        AudioServicesPlaySystemSound(1025)
    }
}
