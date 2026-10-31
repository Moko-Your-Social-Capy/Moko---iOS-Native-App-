//
//  MokoAnimationController.swift
//  Moko
//
//  Controller for managing MOKO animation playback across different app states.

import Foundation

/// Animation playback configuration.
struct LoopPlayMode {
    var isLooping: Bool
    
    init(isInfinite: Bool = true) {
        self.isLooping = isInfinite
    }
}

extension LoopPlayMode {
    static func looping() -> Self {
        return LoopPlayMode(isInfinite: true)
    }
    
    static func singlePlay() -> Self {
        return LoopPlayMode(isInfinite: false)
    }
}

/// Controller for managing MOKO animation playback across different app states.
class MokoAnimationController {
    
    static let shared = MokoAnimationController()
    
    private var currentAnimation: String?
    
    init() {
        registerGlobalObservers()
    }
    
    deinit {
        stopAllAnimations()
    }
    
    func start(
        animationName: String,
        loopMode: LoopPlayMode = .looping(),
        size: CGFloat = 280
    ) {
        self.currentAnimation = animationName
    }
    
    func stop() {
        self.currentAnimation = nil
    }
    
    private func registerGlobalObservers() {}
    
    private func stopAllAnimations() {}
}
