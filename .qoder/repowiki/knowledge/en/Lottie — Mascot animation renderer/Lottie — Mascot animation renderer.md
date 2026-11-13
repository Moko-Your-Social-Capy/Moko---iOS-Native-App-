---
kind: external_dependency
name: Lottie — Mascot animation renderer
slug: lottie-ios
category: external_dependency
category_hints:
    - framework_behavior
scope:
    - '**'
source_files:
    - Moko/Moko/Features/Animation/MokoLottieView.swift
---

### Lottie (airbnb/lottie-ios)
- Role: renders the capybara mascot animations (Hello, Meditation, Listening, Complete, Idle) embedded as JSON in `Moko/Moko/Resources/Animations/`.
- Usage shape: `MokoLottieView` wraps a Lottie view with loop mode and frame width; animations respect iOS Reduce Motion by showing a still frame.
- Known caveat: the top-level `Moko/Features/Animation/MokoLottieView.swift` is a stale duplicate outside the PBXFileSystemSynchronizedRootGroup and does not compile into the app — edits must go under `Moko/Moko/Features/Animation/`.