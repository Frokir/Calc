//
//  ContentView.swift
//  myCalc
//
//  Created by Олег Переплётчиков on 31.07.2025.
//

import SwiftUI

// Button style with press animation
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// Generic calculator button
struct TipicalButton: View {
    var text: String
    var action: () -> Void = {}
    var color: Color = .gray

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.title2)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color)
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                )
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// Main screen
struct ContentView: View {
    @State private var mainText: String = "0"

    private let buttons: [[String]] = [
        ["AC", "(", ")", "⌫"],
        ["7", "8", "9", "/"],
        ["4", "5", "6", "*"],
        ["1", "2", "3", "-"],
        ["0", ".", "=", "+"]
    ]

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text(mainText)
                        .font(.largeTitle)
                        .padding()
                }
                .frame(height: geometry.size.height / 2)

                VStack(spacing: 0) {
                    ForEach(buttons, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(row, id: \.self) { item in
                                TipicalButton(text: item,
                                              action: { handleButton(item) },
                                              color: colorFor(item))
                                    .frame(width: geometry.size.width / 4,
                                           height: geometry.size.height / 10)
                            }
                        }
                    }
                }
                .frame(height: geometry.size.height / 2)
            }
        }
    }

    private func handleButton(_ label: String) {
        switch label {
        case "AC":
            clearText(in: $mainText)
        case "(":
            addValue(addText: "(", to: $mainText)
        case ")":
            addValue(addText: ")", to: $mainText)
        case "⌫":
            myDropLast(in: $mainText)
        case "=":
            resultValue(text: $mainText)
        default:
            addValue(addText: label, to: $mainText)
        }
    }

    private func colorFor(_ label: String) -> Color {
        switch label {
        case "AC", "⌫":
            return .red
        case "+", "-", "*", "/", "=":
            return .orange
        default:
            return .gray
        }
    }
}

#Preview {
    ContentView()
}

