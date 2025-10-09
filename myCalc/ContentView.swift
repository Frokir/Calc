//
//  ContentView.swift
//  myCalc
//
//  Created by OpenAI Assistant on 2024-XX-XX.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: HearingAssistViewModel
    @State private var isSettingsPresented = false
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: HearingAssistViewModel = HearingAssistViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, Color(red: 0.05, green: 0.1, blue: 0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                header

                Spacer()

                EqualizerView(levels: viewModel.equalizerLevels)
                    .frame(height: 240)
                    .padding(.horizontal, 32)

                Spacer()

                controlPanel
            }
            .padding(.vertical, 48)
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(settings: $viewModel.settings)
                .presentationDetents([.medium, .large])
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                viewModel.stop()
            }
        }
        .onDisappear {
            viewModel.stop()
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Text("VibroHear")
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Text(viewModel.isRunning ? "Передача звука активна" : "Готов к передаче")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .animation(.easeInOut(duration: 0.25), value: viewModel.isRunning)
        }
    }

    private var controlPanel: some View {
        HStack(spacing: 24) {
            Button {
                isSettingsPresented = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }

            Spacer()

            PowerButton(isActive: viewModel.isRunning) {
                viewModel.toggle()
            }

            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

struct EqualizerView: View {
    let levels: [CGFloat]

    var body: some View {
        GeometryReader { proxy in
            let barCount = max(levels.count, 1)
            let spacingDenominator = CGFloat(max(barCount * 2 - 1, 1))
            let width = proxy.size.width / spacingDenominator
            HStack(alignment: .bottom, spacing: width) {
                ForEach(levels.indices, id: \.self) { index in
                    RoundedRectangle(cornerRadius: width)
                        .fill(gradient(for: levels[index]))
                        .frame(width: width, height: max(width, proxy.size.height * levels[index].clamped(to: 0...1)))
                        .animation(.easeOut(duration: 0.08), value: levels[index])
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, width / 2)
        }
    }

    private func gradient(for value: CGFloat) -> LinearGradient {
        let base = Color.cyan
        let active = Color.green
        return LinearGradient(colors: [base.opacity(0.7), active.opacity(Double(value))], startPoint: .top, endPoint: .bottom)
    }
}

struct PowerButton: View {
    var isActive: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isActive ? Color.green : Color.white.opacity(0.08))
                    .frame(width: 120, height: 120)
                    .overlay {
                        Circle()
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                    }
                    .shadow(color: Color.green.opacity(isActive ? 0.4 : 0), radius: 20, y: 10)

                Image(systemName: "power")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(isActive ? .black : .white)
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isActive)
    }
}

struct SettingsView: View {
    @Binding var settings: HearingAssistSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Громкость") {
                    Slider(value: Binding(get: {
                        Double(settings.outputVolume)
                    }, set: { newValue in
                        settings.outputVolume = Float(newValue)
                    }), in: 0.1...1.0)
                    Text(String(format: "%.0f %%", settings.outputVolume * 100))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Частотный акцент") {
                    Slider(value: Binding(get: {
                        Double(settings.frequencyShift)
                    }, set: { newValue in
                        settings.frequencyShift = Float(newValue)
                    }), in: -600...600, step: 10)
                    Text(String(format: "%+.0f Гц", settings.frequencyShift))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Ширина диапазона") {
                    Slider(value: Binding(get: {
                        Double(settings.bandwidth)
                    }, set: { newValue in
                        settings.bandwidth = Float(newValue)
                    }), in: 800...3200, step: 50)
                    Text(String(format: "%.0f Гц", settings.bandwidth))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Режим работы") {
                    Label("Используйте iPhone, прижатый к кости за ухом для костной проводимости.", systemImage: "waveform")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .scrollContentBackground(.hidden)
            .background(.ultraThinMaterial)
            .navigationTitle("Настройки")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    #if DEBUG
    ContentView(
        viewModel: HearingAssistViewModel(
            audioEngine: MockAudioEngineService(),
            hapticService: MockHapticFeedbackService()
        )
    )
    .preferredColorScheme(.dark)
    #else
    ContentView()
        .preferredColorScheme(.dark)
    #endif
}
