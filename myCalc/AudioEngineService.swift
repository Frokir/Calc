//
//  AudioEngineService.swift
//  myCalc
//
//  Created by OpenAI Assistant on 2024-XX-XX.
//

import Foundation
import AVFoundation
import Accelerate
import CoreGraphics

/// Describes the adjustable parameters for the speech enhancement pipeline.
struct HearingAssistSettings: Equatable {
    /// Output gain applied after the clean-up chain.
    var outputVolume: Float = 0.8
    /// Value in hertz used to shift the centre frequency inside the speech band.
    var frequencyShift: Float = 0.0
    /// Tunable width of the band-pass filter used to isolate the voice.
    var bandwidth: Float = 2200.0

    static let `default` = HearingAssistSettings()
}

/// Protocol to allow mocking the audio engine in previews and tests.
protocol AudioEngineServiceProtocol {
    var onAmplitudeUpdate: (([Float]) -> Void)? { get set }
    var onHapticUpdate: ((Float) -> Void)? { get set }

    func configure(settings: HearingAssistSettings)
    func start() throws
    func stop()
}

/// Real-time audio pipeline responsible for capturing the microphone signal,
/// enhancing human speech and forwarding simplified data to the haptic engine.
final class AudioEngineService: AudioEngineServiceProtocol {
    private let engine = AVAudioEngine()
    private let eqNode = AVAudioUnitEQ(numberOfBands: 2)
    private let dynamicsNode = AVAudioUnitDynamicsProcessor()
    private let mixerNode = AVAudioMixerNode()

    private let amplitudeQueue = DispatchQueue(label: "AudioEngineService.Amplitude")

    private var currentSettings = HearingAssistSettings.default

    var onAmplitudeUpdate: (([Float]) -> Void)?
    var onHapticUpdate: ((Float) -> Void)?

    init() {
        setupSignalChain()
    }

    private func setupSignalChain() {
        eqNode.globalGain = 0
        let speechBand = eqNode.bands.first
        speechBand?.filterType = .bandPass
        speechBand?.frequency = 1700
        speechBand?.bandwidth = 1.5
        speechBand?.gain = 6
        speechBand?.bypass = false

        if eqNode.bands.count > 1 {
            let highCut = eqNode.bands[1]
            highCut.filterType = .highPass
            highCut.frequency = 250
            highCut.gain = -6
            highCut.bypass = false
        }

        dynamicsNode.threshold = -20
        dynamicsNode.headRoom = 5
        dynamicsNode.expansionRatio = 1.8
        dynamicsNode.attackTime = 0.01
        dynamicsNode.releaseTime = 0.1
        dynamicsNode.masterGain = 0

        engine.attach(eqNode)
        engine.attach(dynamicsNode)
        engine.attach(mixerNode)

        let input = engine.inputNode
        let format = input.inputFormat(forBus: 0)

        engine.connect(input, to: eqNode, format: format)
        engine.connect(eqNode, to: dynamicsNode, format: format)
        engine.connect(dynamicsNode, to: mixerNode, format: format)
        engine.connect(mixerNode, to: engine.mainMixerNode, format: format)

        mixerNode.outputVolume = currentSettings.outputVolume
    }

    func configure(settings: HearingAssistSettings) {
        currentSettings = settings
        updateEQ()
        mixerNode.outputVolume = settings.outputVolume
    }

    func start() throws {
        try configureSession()
        installTap()
        try engine.start()
    }

    func stop() {
        engine.stop()
        mixerNode.removeTap(onBus: 0)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setMode(.voiceChat)
        try session.setPreferredSampleRate(44100)
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func updateEQ() {
        guard let speechBand = eqNode.bands.first else { return }
        let baseFrequency: Float = 1700
        let frequency = max(300, min(4000, baseFrequency + currentSettings.frequencyShift))
        speechBand.frequency = frequency
        speechBand.bandwidth = max(0.3, min(3.5, currentSettings.bandwidth / 1000))
    }

    private func installTap() {
        let bus = 0
        mixerNode.removeTap(onBus: bus)
        let format = mixerNode.outputFormat(forBus: bus)
        let frameCount = AVAudioFrameCount(format.sampleRate / 20) // 50 FPS for the equaliser

        mixerNode.installTap(onBus: bus, bufferSize: frameCount, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            self.process(buffer: buffer)
        }
    }

    private func process(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let channel = channelData[0]
        let frameLength = Int(buffer.frameLength)

        var rms: Float = 0
        vDSP_meansqv(channel, 1, &rms, vDSP_Length(frameLength))
        rms = sqrt(rms)

        let samplesPerBar = max(1, frameLength / 10)
        var barValues: [Float] = []
        barValues.reserveCapacity(10)

        for index in stride(from: 0, to: frameLength, by: samplesPerBar) {
            let count = min(samplesPerBar, frameLength - index)
            if count <= 0 { break }
            var segmentRMS: Float = 0
            vDSP_meansqv(channel + index, 1, &segmentRMS, vDSP_Length(count))
            barValues.append(sqrt(segmentRMS))
        }

        let amplitude = min(1.0, rms * 4)

        amplitudeQueue.async { [weak self] in
            self?.onAmplitudeUpdate?(barValues)
            self?.onHapticUpdate?(amplitude)
        }
    }
}

#if DEBUG
final class MockAudioEngineService: AudioEngineServiceProtocol {
    var onAmplitudeUpdate: (([Float]) -> Void)?
    var onHapticUpdate: ((Float) -> Void)?

    private var timer: Timer?
    private var settings = HearingAssistSettings.default

    func configure(settings: HearingAssistSettings) {
        self.settings = settings
    }

    func start() throws {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self else { return }
            let base = max(0.1, CGFloat(self.settings.outputVolume))
            let levels = (0..<12).map { _ in Float.random(in: 0...1) * Float(base) }
            self.onAmplitudeUpdate?(levels)
            self.onHapticUpdate?(levels.max() ?? 0.2)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
#endif
