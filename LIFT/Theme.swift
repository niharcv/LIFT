//
//  Theme.swift
//  LIFT
//

import SwiftUI

struct Theme {
    // Colors
    static let background = Color(red: 0.05, green: 0.06, blue: 0.09)
    static let cardBackground = Color(red: 0.12, green: 0.15, blue: 0.22)
    static let cardBackgroundPressed = Color(red: 0.18, green: 0.22, blue: 0.32)
    
    // Neon Accents
    static let neonCyan = Color(red: 0.00, green: 0.85, blue: 1.00)
    static let neonPurple = Color(red: 0.64, green: 0.32, blue: 1.00)
    static let neonGold = Color(red: 1.00, green: 0.78, blue: 0.00)
    static let neonOrange = Color(red: 1.00, green: 0.44, blue: 0.18)
    static let neonGreen = Color(red: 0.00, green: 0.90, blue: 0.46)
    
    // Gradients
    static let primaryGradient = LinearGradient(
        colors: [neonCyan, neonPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let goldGradient = LinearGradient(
        colors: [neonGold, neonOrange],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [background, Color(red: 0.08, green: 0.09, blue: 0.15)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Text Styling
    static let textPrimary = Color.white
    static let textSecondary = Color.gray.opacity(0.9)
    static let textTertiary = Color.gray.opacity(0.6)
}

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.cardBackground.opacity(0.7))
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.15), .clear, .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

extension View {
    func glassCard() -> some View {
        self.modifier(GlassCardModifier())
    }
    
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func keyboardDoneButton() -> some View {
        self.modifier(KeyboardDoneButtonModifier())
    }
}

struct KeyboardDoneButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.neonCyan)
                }
            }
    }
}

