//
//  MokoAnimationTypes.swift
//  Moko
//
//  Animation type definitions for MOKO mascot.

import Foundation

/// Represents all available MOKO animation types.
enum MokoAnimationType: String {
    case hello        // Entrance - Welcome to the app
    case meditation    // Meditation - Breathing in pond
    case complete      // Celebration - Completion joy
    case listening      // Conversation - AI interaction
    case idle          // Companion - Default state
    
    var lottieName: String { self.rawValue }
    
    static var all: [MokoAnimationType] {
        return [.hello, .meditation, .complete, .listening, .idle]
    }
}

extension MokoAnimationType {
    static func from(string name: String) -> Self? {
        return Self(rawValue: name)
    }
}
