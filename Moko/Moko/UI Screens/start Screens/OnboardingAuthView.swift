//
//  OnboardingAuthView.swift
//  Moko
//
//  Created for Moko iOS App.
//

import SwiftUI

struct OnboardingAuthView: View {
    var onContinueWithEmail: (String) -> Void = { _ in }
    var onContinueWithApple: () -> Void = {}
    var onContinueWithGoogle: () -> Void = {}
    var onBack: (() -> Void)? = nil
    
    @State private var email: String = ""
    @State private var isEmailFocused: Bool = false
    @State private var hasAppeared = false
    @State private var showTermsSheet = false
    @State private var showPrivacySheet = false
    @State private var avatarBobOffset: CGFloat = 0.0
    
    // Email validity check
    private var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("@") && trimmed.contains(".") && trimmed.count >= 5
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                MokoTheme.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Optional Top Navigation Bar with Back Button
                        HStack {
                            if let onBack = onBack {
                                Button(action: {
                                    MokoTheme.playFeedback(.light)
                                    onBack()
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(MokoTheme.textPrimary)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            Circle()
                                                .fill(Color.white.opacity(0.8))
                                                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                                        )
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        
                        // Top Avatar Area: Sitting Capybara with Orange & Sprout
                        ZStack {
                            // Soft ambient halo glow
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 236/255, green: 245/255, blue: 238/255).opacity(0.85),
                                            Color(red: 250/255, green: 247/255, blue: 242/255).opacity(0.0)
                                        ]),
                                        center: .center,
                                        startRadius: 40,
                                        endRadius: 90
                                    )
                                )
                                .frame(width: 170, height: 170)
                            
                            // Sitting Moko Badge Illustration
                            Image("moko_sitting_raw")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 130, height: 130)
                                .offset(y: avatarBobOffset)
                        }
                        .frame(height: 150)
                        .scaleEffect(hasAppeared ? 1.0 : 0.88)
                        .opacity(hasAppeared ? 1.0 : 0.0)
                        .padding(.top, 10)
                        .padding(.bottom, 24)
                        
                        // Title: Log in or sign up
                        Text("Log in or sign up")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(MokoTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .opacity(hasAppeared ? 1.0 : 0.0)
                            .offset(y: hasAppeared ? 0 : 10)
                            .padding(.bottom, 28)
                        
                        // Email Input Field
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope")
                                    .font(.system(size: 16))
                                    .foregroundColor(MokoTheme.textSecondary)
                                    .padding(.leading, 18)
                                
                                TextField("name@example.com", text: $email)
                                    .font(.system(size: 16, design: .rounded))
                                    .foregroundColor(MokoTheme.textPrimary)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                
                                if !email.isEmpty {
                                    Button(action: {
                                        email = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 15))
                                            .foregroundColor(MokoTheme.textTertiary)
                                    }
                                    .padding(.trailing, 16)
                                    .transition(.opacity)
                                } else {
                                    Color.clear
                                        .frame(width: 16, height: 1)
                                }
                            }
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 26, style: .continuous)
                                    .fill(MokoTheme.cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                                            .stroke(isEmailFocused ? MokoTheme.forestGreen : MokoTheme.borderLight, lineWidth: isEmailFocused ? 1.5 : 1.0)
                                    )
                                    .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                            )
                            
                            // "Continue" Link / Action
                            Button(action: {
                                if isEmailValid {
                                    MokoTheme.playFeedback(.medium)
                                    onContinueWithEmail(email)
                                } else if !email.isEmpty {
                                    MokoTheme.playFeedback(.rigid)
                                }
                            }) {
                                Text("Continue")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(isEmailValid ? MokoTheme.forestGreen : MokoTheme.textSecondary)
                                    .underline(isEmailValid, color: MokoTheme.forestGreen)
                                    .padding(.vertical, 4)
                            }
                            .disabled(email.isEmpty)
                            .opacity(email.isEmpty ? 0.6 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: isEmailValid)
                        }
                        .padding(.horizontal, 24)
                        .opacity(hasAppeared ? 1.0 : 0.0)
                        
                        // Divider with "or"
                        HStack(spacing: 16) {
                            Rectangle()
                                .fill(MokoTheme.borderLight)
                                .frame(height: 1)
                            
                            Text("or")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(MokoTheme.textTertiary)
                            
                            Rectangle()
                                .fill(MokoTheme.borderLight)
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 22)
                        .opacity(hasAppeared ? 1.0 : 0.0)
                        
                        // Social Login Buttons Stack
                        VStack(spacing: 14) {
                            // Apple Sign In Button
                            Button(action: {
                                MokoTheme.playFeedback(.medium)
                                onContinueWithApple()
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "apple.logo")
                                        .font(.system(size: 18))
                                        .offset(y: -1)
                                    
                                    Text("Continue with Apple")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    Capsule()
                                        .fill(MokoTheme.forestGreen)
                                        .shadow(color: MokoTheme.forestGreen.opacity(0.2), radius: 10, x: 0, y: 5)
                                )
                            }
                            .buttonStyle(MokoPrimaryButtonStyle())
                            
                            // Google Sign In Button
                            Button(action: {
                                MokoTheme.playFeedback(.medium)
                                onContinueWithGoogle()
                            }) {
                                HStack(spacing: 12) {
                                    Image("google_logo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 18, height: 18)
                                    
                                    Text("Continue with Google")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    Capsule()
                                        .fill(MokoTheme.forestGreen)
                                        .shadow(color: MokoTheme.forestGreen.opacity(0.2), radius: 10, x: 0, y: 5)
                                )
                            }
                            .buttonStyle(MokoPrimaryButtonStyle())
                        }
                        .padding(.horizontal, 24)
                        .opacity(hasAppeared ? 1.0 : 0.0)
                        
                        Spacer(minLength: 32)
                        
                        // Legal Disclaimer Footer
                        VStack(spacing: 2) {
                            Text("By continuing, you agree to Moko's")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(MokoTheme.textSecondary)
                            
                            HStack(spacing: 4) {
                                Button("Terms of Service") {
                                    showTermsSheet = true
                                }
                                .underline()
                                
                                Text("and")
                                    .foregroundColor(MokoTheme.textSecondary)
                                
                                Button("Privacy Policy") {
                                    showPrivacySheet = true
                                }
                                .underline()
                            }
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(MokoTheme.textPrimary)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 24)
                        .opacity(hasAppeared ? 1.0 : 0.0)
                    }
                    .frame(minHeight: geometry.size.height)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.72)) {
                    hasAppeared = true
                }
                withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                    avatarBobOffset = -3
                }
            }
            .sheet(isPresented: $showTermsSheet) {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Terms of Service")
                                .font(.title.bold())
                            Text("Welcome to Moko. By using our social habit & capybara companionship service, you agree to treat fellow capybara companions with kindness, honesty, and respect. Small daily nudges, an honest chat after, that's it!")
                                .foregroundColor(MokoTheme.textSecondary)
                        }
                        .padding(24)
                    }
                    .navigationTitle("Terms")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showTermsSheet = false }
                        }
                    }
                }
            }
            .sheet(isPresented: $showPrivacySheet) {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Privacy Policy")
                                .font(.title.bold())
                            Text("Your privacy matters to Moko. We keep your chats, nudges, and personal reflections secure and private. We never sell your personal data.")
                                .foregroundColor(MokoTheme.textSecondary)
                        }
                        .padding(24)
                    }
                    .navigationTitle("Privacy")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showPrivacySheet = false }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    OnboardingAuthView(
        onContinueWithEmail: { email in print("Email: \(email)") },
        onContinueWithApple: { print("Apple sign in") },
        onContinueWithGoogle: { print("Google sign in") }
    )
}
