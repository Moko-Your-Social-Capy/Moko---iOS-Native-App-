//
//  MokoLottieView.swift
//  Moko
//
//  Premium reusable Lottie component for MOKO mascot animations.

import SwiftUI
import Lottie

/// Animation type enum representing all available MOKO animation types.
enum MokoAnimationType: String, CaseIterable {
    case hello        // Entrance - Welcome bounce & wave
    case meditation   // Meditation - Breathing in pond with gentle scale
    case complete     // Celebration - Thumbs-up gesture
    case listening    // Conversation - Attentive face
    case idle         // Companion - Gentle resting state
    
    var lottieName: String {
        self.rawValue
    }
}

extension MokoAnimationType {
    /// Returns all available animation types.
    static var all: [MokoAnimationType] {
        [.hello, .meditation, .complete, .listening, .idle]
    }
    
    /// Direct enum case access for convenience.
    static var getHello: MokoAnimationType { .hello }
    static var getMeditation: MokoAnimationType { .meditation }
    static var getComplete: MokoAnimationType { .complete }
    static var getListening: MokoAnimationType { .listening }
    static var getIdle: MokoAnimationType { .idle }
}

/// Animation loop mode configuration for controlling playback behavior.
struct AnimationLoopMode {
    /// Whether this animation should loop or play once.
    let isLooping: Bool
    
    init(isInfinite: Bool = true) {
        self.isLooping = isInfinite
    }
    
    static func looping() -> Self {
        return AnimationLoopMode(isInfinite: true)
    }
    
    static func singlePlay() -> Self {
        return AnimationLoopMode(isInfinite: false)
    }
}

extension AnimationLoopMode {
    var isLooping: Bool { self.isLooping }
}

/// Main Lottie view wrapper for rendering MOKO animations with native integration.
struct MokoLottieView: UIViewRepresentable {
    
    /// Name of the animation file to load (e.g., "MokoHello", "MocoListening")
    var animationName: String = "MokoHello"
    
    /// Controls whether animation loops or plays once
    var loopMode: AnimationLoopMode = .looping()
    
    /// Sets the display size for the animation in points. Default is 280
    var frameWidth: CGFloat = 280
    
    @State private var isPlaying: Bool = false
    
    // MARK: - Required Implementation
    
    /// Creates Lottie view with given animation configuration.
    func makeUIView(context: Context) -> LottieMokoView {
        let mokoView = LottieMokoView(
            animationName: animationName,
            loopMode: loopMode.isLooping,
            width: frameWidth,
            height: frameWidth,
            autoPlay: false
        )
        
        context.viewCoordinator.didInsertView(mokoView)
        
        return mokoView
    }
    
    /// Updates Lottie view properties from current state.
    func updateUIView(_ uiView: LottieMokoView, context: Context) {}
}

// MARK: - Extension on View for convenience usage

extension View {
    /// Convenience method to apply MOKO Lottie animation with defaults.
    func mokoLottie(
        animationName: String = "MocoListening",
        loopMode: AnimationLoopMode = .looping(),
        size: CGFloat = 280
    ) -> some View {
        return self
            .frame(width: size, height: size)
            .overlay(alignment: .topLeading) {
                MokoLottieView(
                    animationName: animationName,
                    loopMode: loopMode,
                    frameWidth: size
                )
                .frame(width: 0, height: 0)
            }
    }
}

// MARK: - Preview Configuration

#Preview {
    ZStack {
        Color.purple.opacity(0.2)
        
        MokoLottieView(
            animationName: "MocoListening",
            loopMode: .looping(),
            frameWidth: 200
        )
        .padding()
    }
}
