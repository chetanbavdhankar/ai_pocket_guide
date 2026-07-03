// HapticsManager.swift — AI Pocket Arena
// UINotificationFeedbackGenerator wrapper, respects user toggle

import UIKit

@MainActor
final class HapticsManager {
    static let shared = HapticsManager()

    private var isEnabled = true

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    func correct() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    func incorrect() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    func streak() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    func tap() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    func selection() {
        guard isEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
