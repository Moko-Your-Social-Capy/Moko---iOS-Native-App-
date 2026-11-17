//
//  OnboardingAuthView.swift
//  Moko
//
//  Start Screen: Log in or sign up with Supabase and Google Sign-In.
//

import SwiftUI
import Supabase
import Auth

struct OnboardingAuthView: View {
    var onAuthenticated: ((User) -> Void)? = nil
    var onContinueWithEmail: ((String) -> Void)? = nil
    var onContinueWithApple: (() -> Void)? = nil
    var onContinueWithGoogle: (() -> Void)? = nil
    
    // Auth Services
    private let auth = AuthService()
    private let googleAuth = GoogleAuthService()
    
    // Input Fields
    @State private var email: String = ""
    @State private var password: String = ""
    
    // Animation & Presentation States
    @State private var hasAppeared = false
    @State private var showTermsSheet = false
    @State private var showPrivacySheet = false
    @State private var showEmailInput = false
    
    // MARK: - Top Image

    private var topImage: some View {
        // The photo fills the upper half of the screen edge-to-edge.
        Image("authImage")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .clipped()
            // Shadow gradient fades the photo into the backdrop at the bottom edge.
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.62),
                        .init(color: .black.opacity(0.2), location: 0.9),
                        .init(color: Color(hex: 0xCBE6D3).opacity(0.95), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            )
            .shadow(color: .black.opacity(0.28), radius: 20, x: 0, y: 12)
    }

    var body: some View {
        ZStack {
            // MARK: - Background (same as other auth screens)
            MokoBackdrop()
            
            VStack(spacing: 0) {
                // Top-half image, blended into the background gradient.
                topImage
                    .frame(height: UIScreen.main.bounds.height * 0.6)
                    .clipped()
                    // Extend into the status-bar area so no green shows above the photo.
                    .ignoresSafeArea(edges: .top)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                
                Spacer()
                
                // MARK: - Title
                Text("Your Social Quest")
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundStyle(MokoTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .padding(.bottom, 40)
                
                // MARK: - Email/Password Input (shown when toggled)
                if showEmailInput {
                    VStack(spacing: 12) {
                        // Email Input Field
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(MokoTheme.forestGreen)
                                
                            
                            TextField("name@example.com", text: $email)
                                .font(.system(size: 16, design: .rounded))
                                .foregroundStyle(MokoTheme.textPrimary)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        .frame(height: 54)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 27, style: .continuous)
                                .fill(Color.white)
                        )
                        
                        // Password Field
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(MokoTheme.forestGreen)
                            
                            SecureField("Password (min 6)", text: $password)
                                .font(.system(size: 16, design: .rounded))
                                .foregroundStyle(MokoTheme.textPrimary)
                                .textContentType(.password)
                        }
                        .frame(height: 54)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 27, style: .continuous)
                                .fill(Color.white)
                        )
                        
                        // Sign In Button
                        Button(action: {
                            onContinueWithEmail?("")
                        }) {
                            Text("Sign In")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    RoundedRectangle(cornerRadius: 27, style: .continuous)
                                        .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                                )
                        }
                        .shadow(color: Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.45), radius: 8, x: 0, y: 4)
                        
                        // Back Button
                        Button(action: {
                            withAnimation {
                                showEmailInput = false
                            }
                        }) {
                            Text("Back")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(MokoTheme.textSecondary)
                        }
                    }
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .transition(.opacity)
                } else {
                    // MARK: - Continue with Email Button (Dark)
                    Button(action: {
                        withAnimation {
                            showEmailInput = true
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 16, weight: .semibold))
                            
                            Text("Continue with Email")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 27, style: .continuous)
                                .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                        )
                    }
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .shadow(color: Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.45), radius: 8, x: 0, y: 4)
                }
                
                // MARK: - Divider "OR"
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(MokoTheme.borderLight)
                        .frame(height: 1)
                    
                    Text("OR")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(MokoTheme.textSecondary)
                    
                    Rectangle()
                        .fill(MokoTheme.borderLight)
                        .frame(height: 1)
                }
                .opacity(hasAppeared ? 1.0 : 0.0)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                
                // MARK: - Apple & Google Icons
                HStack(spacing: 16) {
                    // Apple
                    Button(action: {
                        MokoTheme.playFeedback(.medium)
                        onContinueWithApple?()
                    }) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 27, style: .continuous)
                                    .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                            )
                    }
                    .shadow(color: Color(red: 0.95, green: 0.95, blue: 0.95).opacity(0.7), radius: 8, x: 0, y: 4)

                    // Google
                    Button(action: {
                        MokoTheme.playFeedback(.medium)
                        Task {
                            await signInWithGoogle()
                        }
                    }) {
                        Image("google_logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 27, style: .continuous)
                                    .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                            )
                    }
                    .shadow(color: Color(red: 0.95, green: 0.95, blue: 0.95).opacity(0.7), radius: 8, x: 0, y: 4)
                }
                .opacity(hasAppeared ? 1.0 : 0.0)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.72)) {
                    hasAppeared = true
                }
            }
            .sheet(isPresented: $showTermsSheet) {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Terms of Service")
                                .font(.title.bold())
                                .foregroundStyle(MokoTheme.textPrimary)
                            Text("Welcome to Moko. By using our social habit & capybara companionship service, you agree to treat fellow capybara companions with kindness, honesty, and respect. Small daily nudges, an honest chat after, that's it!")
                                .foregroundStyle(MokoTheme.textSecondary)
                        }
                        .padding(24)
                    }
                    .background(MokoBackdrop())
                    .navigationTitle("Terms")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showTermsSheet = false }
                                .foregroundStyle(MokoTheme.forestGreen)
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
                                .foregroundStyle(MokoTheme.textPrimary)
                            Text("Your privacy matters to Moko. We keep your chats, nudges, and personal reflections secure and private. We never sell your personal data.")
                                .foregroundStyle(MokoTheme.textSecondary)
                        }
                        .padding(24)
                    }
                    .background(MokoBackdrop())
                    .navigationTitle("Privacy")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showPrivacySheet = false }
                                .foregroundStyle(MokoTheme.forestGreen)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Supabase Google Sign In Flow
    
    @MainActor
    private func signInWithGoogle() async {
        do {
            try await googleAuth.signIn()
            let user = try? await auth.getCurrentUser()
            MokoTheme.playNotificationFeedback(.success)
            if let user = user {
                onAuthenticated?(user)
            }
            onContinueWithGoogle?()
        } catch {
            MokoTheme.playNotificationFeedback(.success)
            onContinueWithGoogle?()
        }
    }
}

#Preview {
    OnboardingAuthView()
}
