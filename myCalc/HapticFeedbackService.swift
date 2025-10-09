//
//  HapticFeedbackService.swift
//  myCalc
//
//  Created by OpenAI Assistant on 2024-XX-XX.
//

import Foundation
import CoreHaptics

protocol HapticFeedbackServiceProtocol {
    func prepare() throws
    func play(amplitude: Float)
    func stop()
}

final class HapticFeedbackService: HapticFeedbackServiceProtocol {
    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?
    private let queue = DispatchQueue(label: "HapticFeedbackService")

    func prepare() throws {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        if engine == nil {
            engine = try CHHapticEngine()
            engine?.isAutoShutdownEnabled = true
        }
        try engine?.start()
        try ensureContinuousPlayer()
    }

    func play(amplitude: Float) {
        queue.async { [weak self] in
            guard let self else { return }
            let clamped = CHHapticEventParameter(parameterID: .hapticIntensity, value: max(0.05, min(1, amplitude)))
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
            do {
                if self.player?.isPlaying != true {
                    try self.player?.start(atTime: CHHapticTimeImmediate)
                }
                try self.player?.sendParameters([clamped, sharpness], atTime: 0)
            } catch {
                try? self.engine?.start()
                try? self.ensureContinuousPlayer()
            }
        }
    }

    func stop() {
        queue.async { [weak self] in
            try? self?.player?.stop(atTime: CHHapticTimeImmediate)
            self?.engine?.stop(completionHandler: nil)
        }
    }

    private func ensureContinuousPlayer() throws {
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
        let event = CHHapticEvent(eventType: .continuous, parameters: [intensity, sharpness], relativeTime: 0, duration: 1)
        let pattern = try CHHapticPattern(events: [event], parameters: [])
        player = try engine?.makeAdvancedPlayer(with: pattern)
    }
}

#if DEBUG
final class MockHapticFeedbackService: HapticFeedbackServiceProtocol {
    private(set) var lastAmplitude: Float = 0

    func prepare() throws {}

    func play(amplitude: Float) {
        lastAmplitude = amplitude
    }

    func stop() {
        lastAmplitude = 0
    }
}
#endif
