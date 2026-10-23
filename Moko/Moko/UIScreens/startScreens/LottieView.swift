//
//  LottieView.swift
//  Moko
//
//  A lightweight SwiftUI wrapper around Lottie's LottieAnimationView.
//  Supports looping, autoplay, and speed control.
//

import SwiftUI
import Lottie

/// SwiftUI-native wrapper for Lottie animations using UIViewRepresentable.
struct LottieView: UIViewRepresentable {
    let animationName: String
    var loopMode: LottieLoopMode = .loop
    var animationSpeed: CGFloat = 1.0
    var contentMode: UIView.ContentMode = .scaleAspectFit
    
    func makeUIView(context: Context) -> some UIView {
        let containerView = UIView(frame: .zero)
        containerView.backgroundColor = .clear
        
        let animationView = LottieAnimationView(name: animationName)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.loopMode = loopMode
        animationView.animationSpeed = animationSpeed
        animationView.contentMode = contentMode
        animationView.backgroundColor = .clear
        
        containerView.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: containerView.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        animationView.play()
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        // Animation plays automatically on creation
    }
}

#Preview {
    ZStack {
        MokoTheme.background.ignoresSafeArea()
        LottieView(animationName: "moko_jump_wave")
            .frame(width: 250, height: 250)
    }
}
