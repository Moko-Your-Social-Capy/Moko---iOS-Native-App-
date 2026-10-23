//
//  OnboardingAuthView.swift
//  Moko
//
//  Start Screen 3: Log in or sign up with Supabase and Google Sign-In.
//

import SwiftUI
import Supabase
import Auth

struct OnboardingAuthView: View {
    var onAuthenticated: ((User) -> Void)? = nil
    var onContinueWithEmail: ((String) -> Void)? = nil
    var onContinueWithApple: (() -> Void)? = nil
    var onContinueWithGoogle: (() -> Void)? = nil
    var onBack: (() -> Void)? = nil
    
    // Auth Services
    private let auth = AuthService()
    private let googleAuth = GoogleAuthService()
    
    // Input Fields
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSignUpMode: Bool = false
    @State private var showPasswordField: Bool = false
    
    // Status & Loading
    @State private var message: String = ""
    @State private var isError: Bool = false
    @State private var isLoading: Bool = false
    @State private var isGoogleLoading: Bool = false
    
    // Animation & Presentation States
    @State private var hasAppeared = false
    @State private var showTermsSheet = false
    @State private var showPrivacySheet = false
    @State private var avatarBobOffset: CGFloat = 0.0
    
    private var cleanEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var isEmailValid: Bool {
        cleanEmail.contains("@") && cleanEmail.contains(".") && cleanEmail.count >= 5
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                MokoTheme.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Top Bar with Optional Back Navigation
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
                                                .fill(MokoTheme.white.opacity(0.9))
                                                .shadow(color: MokoTheme.primaryText.opacity(0.06), radius: 6, x: 0, y: 2)
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
                                            MokoTheme.warmNeutral.opacity(0.9),
                                            MokoTheme.background.opacity(0.0)
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
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                        
                        // Title: Log in or sign up
                        Text("Log in or sign up")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(MokoTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .opacity(hasAppeared ? 1.0 : 0.0)
                            .offset(y: hasAppeared ? 0 : 10)
                            .padding(.bottom, 24)
                        
                        // Email & Password Fields Container
                        VStack(spacing: 12) {
                            // Email Input Field
                            HStack(spacing: 12) {
                                Image(systemName: "envelope")
                                    .font(.system(size: 16))
                                    .foregroundColor(MokoTheme.textSecondary)
                                    .padding(.leading, 18)
                                
                                TextField("name@example.com", text: $email)
                                    .font(.system(size: 16, design: .rounded))
                                    .foregroundColor(MokoTheme.textPrimary)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                
                                if !email.isEmpty {
                                    Button(action: {
                                        email = ""
                                        message = ""
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 15))
                                            .foregroundColor(MokoTheme.textSecondary.opacity(0.6))
                                    }
                                    .padding(.trailing, 16)
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
                                            .stroke(MokoTheme.borderLight, lineWidth: 1.0)
                                    )
                                    .shadow(color: MokoTheme.primaryText.opacity(0.03), radius: 6, x: 0, y: 2)
                            )
                            
                            // Optional Password Field (revealed when entering credentials)
                            if showPasswordField {
                                HStack(spacing: 12) {
                                    Image(systemName: "lock")
                                        .font(.system(size: 16))
                                        .foregroundColor(MokoTheme.textSecondary)
                                        .padding(.leading, 18)
                                    
                                    SecureField("Password (min 6 characters)", text: $password)
                                        .font(.system(size: 16, design: .rounded))
                                        .foregroundColor(MokoTheme.textPrimary)
                                        .textContentType(.password)
                                }
                                .frame(height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                                        .fill(MokoTheme.cardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                                .stroke(MokoTheme.borderLight, lineWidth: 1.0)
                                        )
                                        .shadow(color: MokoTheme.primaryText.opacity(0.03), radius: 6, x: 0, y: 2)
                                )
                                .transition(.opacity.combined(with: .move(edge: .top)))
                                
                                // Mode Toggle: Sign In vs Create Account
                                HStack(spacing: 8) {
                                    Button(action: {
                                        withAnimation { isSignUpMode.toggle() }
                                    }) {
                                        Text(isSignUpMode ? "Already have an account? Sign In" : "Need an account? Create one")
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundColor(MokoTheme.textSecondary)
                                            .underline()
                                    }
                                }
                                .padding(.top, 4)
                            }
                            
                            // "Continue" Action Button
                            Button(action: {
                                handleContinueAction()
                            }) {
                                HStack(spacing: 8) {
                                    if isLoading {
                                        ProgressView()
                                            .tint(MokoTheme.forestGreen)
                                            .scaleEffect(0.85)
                                    }
                                    
                                    Text(showPasswordField ? (isSignUpMode ? "Create Account" : "Sign In") : "Continue")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundColor(isEmailValid ? MokoTheme.forestGreen : MokoTheme.textSecondary)
                                        .underline(isEmailValid, color: MokoTheme.forestGreen)
                                }
                                .padding(.vertical, 4)
                            }
                            .disabled(email.isEmpty || isLoading)
                            .opacity(email.isEmpty ? 0.6 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: isEmailValid)
                            
                            // Feedback / Status Message
                            if !message.isEmpty {
                                Text(message)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(isError ? MokoTheme.primaryText : MokoTheme.forestGreen)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 4)
                                    .padding(.horizontal, 16)
                                    .transition(.opacity)
                            }
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
                        .padding(.vertical, 20)
                        .opacity(hasAppeared ? 1.0 : 0.0)
                        
                        // Social Sign In Buttons Stack
                        VStack(spacing: 14) {
                            // Apple Sign In Button
                            Button(action: {
                                MokoTheme.playFeedback(.medium)
                                onContinueWithApple?()
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "apple.logo")
                                        .font(.system(size: 18))
                                        .offset(y: -1)
                                    
                                    Text("Continue with Apple")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(MokoTheme.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    Capsule()
                                        .fill(MokoTheme.forestGreen)
                                        .shadow(color: MokoTheme.forestGreen.opacity(0.2), radius: 10, x: 0, y: 5)
                                )
                            }
                            .buttonStyle(MokoPrimaryButtonStyle())
                            .disabled(isLoading || isGoogleLoading)
                            
                            // Google Sign In Button (Connected to Supabase via GoogleAuthService)
                            Button(action: {
                                MokoTheme.playFeedback(.medium)
                                Task {
                                    await signInWithGoogle()
                                }
                            }) {
                                HStack(spacing: 12) {
                                    if isGoogleLoading {
                                        ProgressView()
                                            .tint(MokoTheme.white)
                                            .scaleEffect(0.9)
                                    } else {
                                        Image("google_logo")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 18, height: 18)
                                    }
                                    
                                    Text("Continue with Google")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(MokoTheme.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    Capsule()
                                        .fill(MokoTheme.forestGreen)
                                        .shadow(color: MokoTheme.forestGreen.opacity(0.2), radius: 10, x: 0, y: 5)
                                )
                            }
                            .buttonStyle(MokoPrimaryButtonStyle())
                            .disabled(isLoading || isGoogleLoading)
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
                                .foregroundColor(MokoTheme.textPrimary)
                            Text("Welcome to Moko. By using our social habit & capybara companionship service, you agree to treat fellow capybara companions with kindness, honesty, and respect. Small daily nudges, an honest chat after, that's it!")
                                .foregroundColor(MokoTheme.textSecondary)
                        }
                        .padding(24)
                    }
                    .background(MokoTheme.background.ignoresSafeArea())
                    .navigationTitle("Terms")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showTermsSheet = false }
                                .foregroundColor(MokoTheme.forestGreen)
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
                                .foregroundColor(MokoTheme.textPrimary)
                            Text("Your privacy matters to Moko. We keep your chats, nudges, and personal reflections secure and private. We never sell your personal data.")
                                .foregroundColor(MokoTheme.textSecondary)
                        }
                        .padding(24)
                    }
                    .background(MokoTheme.background.ignoresSafeArea())
                    .navigationTitle("Privacy")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showPrivacySheet = false }
                                .foregroundColor(MokoTheme.forestGreen)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Email Continue & Supabase Authentication Flow
    
    private func handleContinueAction() {
        guard isEmailValid else {
            isError = true
            message = "Please enter a valid email address."
            MokoTheme.playFeedback(.rigid)
            return
        }
        
        // If password is not yet shown, reveal password field smoothly
        if !showPasswordField {
            MokoTheme.playFeedback(.light)
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                showPasswordField = true
                message = ""
            }
            return
        }
        
        // Execute Supabase Auth with email & password
        Task {
            await authenticateWithSupabase()
        }
    }
    
    @MainActor
    private func authenticateWithSupabase() async {
        guard !cleanEmail.isEmpty, !password.isEmpty else {
            isError = true
            message = "Please enter both email and password."
            MokoTheme.playFeedback(.rigid)
            return
        }
        
        guard password.count >= 6 else {
            isError = true
            message = "Password must contain at least 6 characters."
            MokoTheme.playFeedback(.rigid)
            return
        }
        
        isLoading = true
        message = ""
        isError = false
        defer { isLoading = false }
        
        do {
            if isSignUpMode {
                try await auth.signUp(
                    email: cleanEmail,
                    password: password
                )
                
                do {
                    let user = try await auth.getCurrentUser()
                    MokoTheme.playNotificationFeedback(.success)
                    onAuthenticated?(user)
                    onContinueWithEmail?(user.email ?? cleanEmail)
                } catch {
                    isError = false
                    message = "Account created! Check your email to verify, then sign in."
                }
            } else {
                try await auth.signIn(
                    email: cleanEmail,
                    password: password
                )
                
                let user = try await auth.getCurrentUser()
                MokoTheme.playNotificationFeedback(.success)
                onAuthenticated?(user)
                onContinueWithEmail?(user.email ?? cleanEmail)
            }
        } catch {
            isError = true
            message = error.localizedDescription
            MokoTheme.playNotificationFeedback(.error)
        }
    }
    
    // MARK: - Supabase Google Sign In Flow
    
    @MainActor
    private func signInWithGoogle() async {
        isGoogleLoading = true
        message = ""
        isError = false
        defer { isGoogleLoading = false }
        
        do {
            try await googleAuth.signIn()
            let user = try await auth.getCurrentUser()
            MokoTheme.playNotificationFeedback(.success)
            onAuthenticated?(user)
            onContinueWithGoogle?()
        } catch {
            isError = true
            message = error.localizedDescription
            MokoTheme.playNotificationFeedback(.error)
        }
    }
}

#Preview {
    OnboardingAuthView()
}
