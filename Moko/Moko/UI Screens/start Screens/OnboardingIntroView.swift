//
//  OnboardingIntroView.swift
//  Moko
//
//  Created for Moko iOS App.
//

import SwiftUI

struct OnboardingIntroView: View {
    var onLetsBegin: () -> Void = {}
    
    // Animation States
    @State private var hasAppeared = false
    @State private var mokoBobOffset: CGFloat = 0.0
    @State private var sparkleScale: CGFloat = 0.9
    @State private var waveAngle: Double = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Warm Ivory Background
                MokoTheme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer(minLength: 20)
                    
                    // Waving Moko Capybara Illustration Area
                    ZStack {
                        // Soft Floor Shadow
                        Ellipse()
                            .fill(Color.black.opacity(0.05))
                            .frame(width: 170, height: 18)
                            .offset(y: 112)
                            .blur(radius: 2)
                        
                        // Moko Illustration
                        Image("moko_waving_raw")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: min(geometry.size.width * 0.58, 240))
                            .rotationEffect(.degrees(waveAngle), anchor: .bottom)
                            .offset(y: mokoBobOffset)
                    }
                    .frame(height: 260)
                    .scaleEffect(hasAppeared ? 1.0 : 0.88)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .padding(.bottom, 24)
                    
                    // Title
                    Text("Hello, I’m Moko.")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(MokoTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .opacity(hasAppeared ? 1.0 : 0.0)
                        .offset(y: hasAppeared ? 0 : 12)
                    
                    // Subtitle
                    Text("Small daily nudges, an honest chat\nafter, that's it!")
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundColor(MokoTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.top, 12)
                        .padding(.horizontal, 32)
                        .opacity(hasAppeared ? 1.0 : 0.0)
                        .offset(y: hasAppeared ? 0 : 16)
                    
                    Spacer(minLength: 40)
                    
                    // Primary Action Button: "Let's Begin"
                    Button(action: {
                        MokoTheme.playFeedback(.medium)
                        onLetsBegin()
                    }) {
                        Text("Let's Begin")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                Capsule()
                                    .fill(MokoTheme.forestGreen)
                                    .shadow(color: MokoTheme.forestGreen.opacity(0.25), radius: 12, x: 0, y: 6)
                            )
                    }
                    .buttonStyle(MokoPrimaryButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    .opacity(hasAppeared ? 1.0 : 0.0)
                    .offset(y: hasAppeared ? 0 : 20)
                }
                .padding(.top, geometry.safeAreaInsets.top > 0 ? 0 : 16)
                .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.72)) {
                    hasAppeared = true
                }
                
                // Gentle ambient breathing & waving animation
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    mokoBobOffset = -4
                }
                
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true).delay(0.2)) {
                    waveAngle = 1.5
                }
            }
        }
    }
}

#Preview {
    OnboardingIntroView(onLetsBegin: {
        print("Let's begin tapped")
    })
}
