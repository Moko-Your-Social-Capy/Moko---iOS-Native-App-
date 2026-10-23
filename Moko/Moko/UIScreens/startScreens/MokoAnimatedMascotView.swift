//
//  MokoAnimatedMascotView.swift
//  Moko
//
//  Playful animated mascot featuring Lottie animation with jump, wave,
//  squash-and-stretch dynamics, and interactive tap-to-bounce.
//  Falls back to pure SwiftUI animation if Lottie file isn't available.
//

import SwiftUI
import Lottie

struct MokoAnimatedMascotView: View {
    var size: CGFloat = 220
    var autoPlayJump: Bool = true
    
    // Lottie availability check
    @State private var useLottie: Bool = true
    
    // SwiftUI Fallback Animation States
    @State private var jumpOffsetY: CGFloat = 0.0
    @State private var squashX: CGFloat = 1.0
    @State private var stretchY: CGFloat = 1.0
    @State private var shadowScale: CGFloat = 1.0
    @State private var shadowOpacity: Double = 0.05
    @State private var waveRotation: Double = 0.0
    @State private var sparkleScale: CGFloat = 1.0
    @State private var sparkleOpacity: Double = 0.9
    @State private var ambientBreath: CGFloat = 0.0
    @State private var isJumping: Bool = false
    
    var body: some View {
        ZStack {
            if useLottie {
                // Lottie Animation — Smooth 30fps jump + wave + squash-and-stretch
                LottieView(
                    animationName: "moko_jump_wave",
                    loopMode: .loop,
                    animationSpeed: 0.85
                )
                .frame(width: size, height: size)
                .overlay(
                    // Overlay the actual mascot image on top of the Lottie shape animation
                    // so we get the Lottie physics with the real mascot art
                    Image("moko_waving_raw")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size * 0.85, height: size * 0.85)
                        .allowsHitTesting(false)
                        .opacity(0) // Hidden — Lottie handles the full animation
                )
            } else {
                // Pure SwiftUI Fallback
                swiftUIFallbackView
            }
        }
        .frame(width: size, height: size + 30)
        .onAppear {
            // Check if Lottie animation file exists
            if LottieAnimation.named("moko_jump_wave") == nil {
                useLottie = false
                startSwiftUIAnimations()
            }
        }
    }
    
    // MARK: - SwiftUI Fallback View
    
    @ViewBuilder
    private var swiftUIFallbackView: some View {
        ZStack {
            // Dynamic Floor Shadow
            Ellipse()
                .fill(MokoTheme.primaryText.opacity(shadowOpacity))
                .frame(width: size * 0.72 * shadowScale, height: 16 * shadowScale)
                .offset(y: size * 0.44)
                .blur(radius: isJumping ? 4 : 2)
                .animation(.spring(response: 0.38, dampingFraction: 0.7), value: shadowScale)
                .animation(.easeInOut(duration: 0.3), value: shadowOpacity)
            
            // Mascot Character
            ZStack {
                Image("moko_waving_raw")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .scaleEffect(x: squashX, y: stretchY, anchor: .bottom)
                    .rotationEffect(.degrees(waveRotation), anchor: .bottom)
                    .offset(y: jumpOffsetY + ambientBreath)
                
                // Sparkle Accents
                VStack {
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color(red: 255/255, green: 215/255, blue: 0/255).opacity(sparkleOpacity))
                            .frame(width: 6, height: 6)
                            .scaleEffect(sparkleScale)
                            .offset(x: -size * 0.16, y: -size * 0.18)
                    }
                    Spacer()
                }
                .frame(width: size, height: size)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                performPlayfulJump()
            }
        }
    }
    
    // MARK: - SwiftUI Animation Helpers
    
    private func startSwiftUIAnimations() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            waveRotation = 2.0
            sparkleScale = 1.25
            sparkleOpacity = 1.0
        }
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true).delay(0.2)) {
            ambientBreath = -3.5
        }
        if autoPlayJump {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                performPlayfulJump()
            }
        }
    }
    
    func performPlayfulJump() {
        guard !isJumping else { return }
        isJumping = true
        MokoTheme.playFeedback(.light)
        
        withAnimation(.easeOut(duration: 0.12)) {
            squashX = 1.09; stretchY = 0.91
            jumpOffsetY = 3; shadowScale = 1.15; shadowOpacity = 0.08
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.58)) {
                jumpOffsetY = -26; squashX = 0.93; stretchY = 1.08
                shadowScale = 0.62; shadowOpacity = 0.02; waveRotation = 3.5
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.44) {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.55)) {
                jumpOffsetY = 0; squashX = 1.06; stretchY = 0.94
                shadowScale = 1.1; shadowOpacity = 0.06
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.68) {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                squashX = 1.0; stretchY = 1.0; shadowScale = 1.0
                shadowOpacity = 0.05; waveRotation = 0.0; isJumping = false
            }
        }
    }
}

#Preview {
    ZStack {
        MokoTheme.background.ignoresSafeArea()
        MokoAnimatedMascotView(size: 220)
    }
}
