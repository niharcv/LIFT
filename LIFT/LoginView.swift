//
//  LoginView.swift
//  LIFT
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = false
    
    var body: some View {
        ZStack {
            // Background
            Theme.backgroundGradient
                .ignoresSafeArea()
            
            // Neon Glow circles
            VStack {
                HStack {
                    Circle()
                        .fill(Theme.neonCyan.opacity(0.15))
                        .frame(width: 200, height: 200)
                        .blur(radius: 60)
                        .offset(x: -50, y: -50)
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    Circle()
                        .fill(Theme.neonPurple.opacity(0.15))
                        .frame(width: 250, height: 250)
                        .blur(radius: 80)
                        .offset(x: 50, y: 50)
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header Logo
                VStack(spacing: 10) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Theme.primaryGradient)
                        .shadow(color: Theme.neonCyan.opacity(0.5), radius: 15)
                    
                    Text("LIFT")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(3)
                    
                    Text("BUILD YOUR LEGACY")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.neonCyan)
                        .tracking(4)
                }
                .padding(.top, 40)
                
                // Form Container
                VStack(spacing: 20) {
                    Text(isRegistering ? "CREATE ACCOUNT" : "WELCOME BACK")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1.5)
                        .padding(.bottom, 5)
                    
                    // Email
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(Theme.neonCyan)
                            .frame(width: 24)
                        
                        TextField("", text: $email, prompt: Text("Email Address").foregroundColor(.white.opacity(0.4)))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .foregroundColor(.white)
                            .keyboardType(.emailAddress)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    
                    // Password
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(Theme.neonPurple)
                            .frame(width: 24)
                        
                        SecureField("", text: $password, prompt: Text("Password").foregroundColor(.white.opacity(0.4)))
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    
                    // Error message
                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Submit button
                    Button(action: handleAuth) {
                        HStack {
                            if authManager.isAuthenticating {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Text(isRegistering ? "GET STARTED" : "LOG IN")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.primaryGradient)
                        .cornerRadius(12)
                        .shadow(color: Theme.neonCyan.opacity(0.3), radius: 10, y: 5)
                    }
                    .disabled(authManager.isAuthenticating || email.isEmpty || password.isEmpty)
                    .padding(.top, 10)
                }
                .padding(30)
                .glassCard()
                .padding(.horizontal, 24)
                
                // Toggle Mode button
                Button(action: {
                    withAnimation(.spring()) {
                        isRegistering.toggle()
                        authManager.errorMessage = nil
                    }
                }) {
                    HStack(spacing: 6) {
                        Text(isRegistering ? "Already have an account?" : "Don't have an account?")
                            .foregroundColor(.white.opacity(0.6))
                        Text(isRegistering ? "Sign In" : "Sign Up")
                            .foregroundColor(Theme.neonCyan)
                            .fontWeight(.bold)
                    }
                    .font(.footnote)
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    private func handleAuth() {
        if isRegistering {
            authManager.register(email: email, password: password)
        } else {
            authManager.login(email: email, password: password)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
