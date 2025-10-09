//
//  HearingAssistViewModel.swift
//  myCalc
//
//  Created by OpenAI Assistant on 2024-XX-XX.
//

import Foundation
import SwiftUI

@MainActor
final class HearingAssistViewModel: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var equalizerLevels: [CGFloat] = Array(repeating: 0.05, count: 12)
    @Published var settings = HearingAssistSettings.default {
        didSet {
            audioEngine.configure(settings: settings)
        }
    }
    @Published private(set) var lastErrorMessage: String?

    private let audioEngine: AudioEngineServiceProtocol
    private let hapticService: HapticFeedbackServiceProtocol

    init(
        audioEngine: AudioEngineServiceProtocol = AudioEngineService(),
        hapticService: HapticFeedbackServiceProtocol = HapticFeedbackService()
    ) {
        self.audioEngine = audioEngine
        self.hapticService = hapticService

        audioEngine.onAmplitudeUpdate = { [weak self] levels in
            DispatchQueue.main.async {
                self?.updateEqualizer(with: levels)
            }
        }

        audioEngine.onHapticUpdate = { [weak self] amplitude in
            self?.hapticService.play(amplitude: amplitude)
        }

        audioEngine.configure(settings: settings)
    }

    func start() {
        guard !isRunning else { return }
        do {
            audioEngine.configure(settings: settings)
            try hapticService.prepare()
            try audioEngine.start()
            withAnimation(.easeInOut(duration: 0.3)) {
                isRunning = true
                lastErrorMessage = nil
            }
        } catch {
            isRunning = false
            if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
                lastErrorMessage = description
            } else {
                lastErrorMessage = error.localizedDescription
            }
        }
    }

    func stop() {
        guard isRunning else {
            lastErrorMessage = nil
            return
        }
        audioEngine.stop()
        hapticService.stop()
        withAnimation(.easeInOut(duration: 0.2)) {
            isRunning = false
            equalizerLevels = Array(repeating: 0.05, count: equalizerLevels.count)
        }
        lastErrorMessage = nil
    }

    func toggle() {
        isRunning ? stop() : start()
    }

    private func updateEqualizer(with levels: [Float]) {
        let clamped = levels.map { max(0, min(1, $0)) }
        let targetCount = equalizerLevels.count
        if clamped.count != targetCount {
            let resized = stride(from: 0, to: targetCount, by: 1).map { index -> CGFloat in
                let position = CGFloat(index) / CGFloat(max(targetCount - 1, 1))
                let sourceIndex = Int(position * CGFloat(max(clamped.count - 1, 1)))
                return CGFloat(clamped[sourceIndex])
            }
            withAnimation(.linear(duration: 0.05)) {
                equalizerLevels = resized
            }
        } else {
            let converted = clamped.map { CGFloat($0) }
            withAnimation(.linear(duration: 0.05)) {
                equalizerLevels = converted
            }
        }
    }
}
