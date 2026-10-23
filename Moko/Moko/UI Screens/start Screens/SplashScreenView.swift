//
//  SplashScreenView.swift
//  Moko
//
//  Created for Moko iOS App.
//

import SwiftUI

struct SplashScreenView: View {
    var autoAdvance: Bool = true
    var onFinished: () -> Void = {}
    
    // Animation States
    @State private var isAnimating = false
    @State private var leavesVisible = false
    @State private var iconScale: CGFloat = 0.8
    @State private var iconOpacity: Double = 0.0
    @State private var textOffset: CGFloat = 16
    @State private var textOpacity: Double = 0.0
    @State private var floatingOffset: CGFloat = 0.0
    @State private var pulseGlow: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                MokoTheme.background
                    .ignoresSafeArea()
                
                // Top-Left Botanical Leaves Overlay
                VStack {
                    HStack {
                        Image("splash_leaves_top_raw")
                            .resizable()
                            .renderingMode(.original)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geometry.size.width * 0.38)
                            .opacity(leavesVisible ? 0.85 : 0.0)
                            .scaleEffect(leavesVisible ? 1.0 : 0.85, anchor: .topLeading)
                            .offset(x: leavesVisible ? 0 : -10, y: leavesVisible ? 0 : -10)
                        Spacer()
                    }
                    Spacer()
                }
                .ignoresSafeArea()
                
                // Bottom-Left Eucalyptus Sprig Overlay
                VStack {
                    Spacer()
                    HStack {
                        Image("splash_leaves_bottom_raw")
                            .resizable()
                            .renderingMode(.original)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geometry.size.width * 0.42)
                            .opacity(leavesVisible ? 0.9 : 0.0)
                            .scaleEffect(leavesVisible ? 1.0 : 0.9, anchor: .bottomLeading)
                            .offset(x: leavesVisible ? 0 : -15, y: leavesVisible ? 0 : 15)
                        Spacer()
                    }
                }
                .ignoresSafeArea()
                
                // Center Brand Elements
                VStack(spacing: 0) {
                    Spacer()
                    
                    // App Icon Card with Moko Capybara
                    ZStack {
                        // Soft ambient glow behind card
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(MokoTheme.warmNeutral.opacity(0.6))
                            .frame(width: 144, height: 144)
                            .scaleEffect(pulseGlow)
                            .blur(radius: 12)
                        
                        // Icon card container
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(MokoTheme.cardBackground)
                            .frame(width: 126, height: 126)
                            .overlay(
                                RoundedRectangle(cornerRadius: 30, style: .continuous)
                                    .stroke(MokoTheme.white.opacity(0.9), lineWidth: 1.5)
                            )
                            .shadow(color: MokoTheme.primaryText.opacity(0.08), radius: 20, x: 0, y: 10)
                            .shadow(color: MokoTheme.forestGreen.opacity(0.06), radius: 8, x: 0, y: 4)
                        
                        // Moko Illustration inside card
                        Image("moko_splash_icon_raw")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 114, height: 114)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    }
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
                    .offset(y: floatingOffset)
                    
                    // Small floral emblem below icon
                    MokoFlowerOrnament(size: 11, color: MokoTheme.forestGreen.opacity(0.85))
                        .padding(.top, 24)
                        .padding(.bottom, 14)
                        .opacity(textOpacity)
                        .scaleEffect(textOpacity)
                    
                    // App Name "Moko"
                    Text("Moko")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(MokoTheme.textPrimary)
                        .tracking(0.5)
                        .opacity(textOpacity)
                        .offset(y: textOffset)
                    
                    // Subtitle
                    Text("Your social  Capybara")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(MokoTheme.textSecondary)
                        .tracking(0.2)
                        .padding(.top, 6)
                        .opacity(textOpacity)
                        .offset(y: textOffset)
                    
                    Spacer()
                    
                    // Subtle skip hint or safe area balance
                    Color.clear
                        .frame(height: 40)
                }
                .padding(.horizontal, 24)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // Immediate skip on tap
                MokoTheme.playFeedback(.light)
                onFinished()
            }
            .onAppear {
                startSplashAnimation()
            }
        }
    }
    
    // MARK: - Orchestrated Animation Sequence
    private func startSplashAnimation() {
        // Step 1: Pop in the icon card with smooth spring
        withAnimation(.spring(response: 0.65, dampingFraction: 0.68, blendDuration: 0)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }
        
        // Step 2: Fade in leaves with organic stagger
        withAnimation(.easeInOut(duration: 0.9).delay(0.2)) {
            leavesVisible = true
        }
        
        // Step 3: Reveal texts smoothly
        withAnimation(.spring(response: 0.55, dampingFraction: 0.75).delay(0.35)) {
            textOffset = 0
            textOpacity = 1.0
        }
        
        // Step 4: Gentle ambient floating & breathing effect
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true).delay(0.7)) {
            floatingOffset = -5
            pulseGlow = 1.06
        }
        
        // Step 5: Automatically transition to Onboarding Intro after delay if enabled
        if autoAdvance {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                onFinished()
            }
        }
    }
}

#Preview {
    SplashScreenView(onFinished: {
        print("Splash finished")
    })
}
