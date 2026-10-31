# MOKO — Premium Mascot Animation & Lottie Integration System

> **Project:** MOKO - Apple-native social wellness and self-improvement application  
> **Platform:** iOS / macOS / tvOS  
> **Status:** Implementation Ready

---

## Overview

This document outlines the complete implementation for integrating premium Lottie animations with the MOKO capybara mascot throughout the app. All five required animations have been created following the design brief specifications.

---

## Quick Links

| Feature | Status | Documentation Link |
|---------|--------|-------------------|
| 5 Lottie Animations | ✅ Created | [`Animation_Integration.md`](#animation-integration) |
| SwiftUI Wrapper Component | ✅ Ready | `Moko/Moko/Features/Animation/MokoLottieView.swift` |
| Animation Controller | ✅ Implemented | `Moko/Moko/Features/Animation/MokoAnimationController.swift` |
| Screen Integration Guide | ✅ Complete | [`Animation_Integration.md`](#animation-integration) |

---

## 📦 Deliverables

### 1. Five Lottie Animation Files

All JSON files located at:
```
Moko/Moko/Resources/Animations/
├── MokoHello.json        # Welcome entrance animation
├── MokoMeditation.json   # Breathing meditation pose
├── MocoListening.json    # Attentive listening state
├── MokoComplete.json     # Celebration with thumbs-up
└── MokoIdle.json         # Gentle companion idle state
```

### 2. SwiftUI Components

| File | Purpose | Location |
|------|---------|----------|
| `MokoLottieView.swift` | Main wrapper for animation display | `Moko/Moko/Features/Animation/` |
| `MokoAnimationTypes.swift` | Enum definitions and loop modes | Same folder |
| `MokoAnimationController.swift` | Playback state management | Same folder |

### 3. Integration Documentation

- [`Animation_Integration.md`](#animation-integration) — Quick start guide for integration
- [`AnimationImplementationGuide.md`](./AnimationImplementationGuide.md) — Full technical details

---

## 🎨 Animation Specifications

| Name | Filename | Duration | Loop Mode | Use Case |
|------|----------|----------|-----------|----------|
| Hello Entrance | `MokoHello.json` | 2.5s (one-shot) | Play Once | Opening welcome screen |
| Meditation | `MokoMeditation.json` | 4s (continuous) | Loop | Breathing / Calm Down screens |
| Complete | `MocoComplete.json` | 2.5s (one-shot) | Play Once | Quest/achievement celebration |
| Listening | `MocoListening.json` | 3s (continuous) | Loop | AI conversation interface |
| Idle | `MokoIdle.json` | 2.5s (continuous) | Loop | Dashboard / default companion state |

---

## 🎯 Color Palette

All animations use MOKO's official color system:

| Color | Hex | Usage |
|-------|-----|-------|
| Forest Green | `#1B422F` | Primary branding |
| Light Mint | `#CBE6D3` | Background gradients |
| Warm Cream | `#DAC095` | Skin tone base |
| Capybara Brown | `#C7A778` | Mascot body color |
| Dark Outline | `#4A3826` | Character outlines |
| Lime Green | `#B7DB75` | Accent highlights |

---

## ⚡ Getting Started

### Step 1: Add Lottie Package

```bash
cd /Users/user42/Documents/Moko---iOS-Native-App-/Moko
open Moko.xcodeproj
```

In Xcode, select **Package Dependencies** tab and add:
```
https://github.com/airbnb/lottie-ios
```

### Step 2: Import in Views

```swift
import Lottie
```

### Step 3: Use Animations

```swift
MokoLottieView(
    animationName: "MocoListening",
    loopMode: .looping,
    frameWidth: 280
)
```

---

## 📁 Project Structure

```
Moko---iOS-Native-App-/
├── Animation_Integration.md          # Quick start guide
├── AnimationImplementationGuide.md   # Full technical documentation
├── Moko.xcodeproj/
│   └── project.pbxproj              # Include Lottie in build phase
├── Moko/
│   ├── Features/
│   │   └── Animation/               # Animation framework code
│   │       ├── MokoLottieView.swift
│   │       ├── MokoAnimationTypes.swift
│   │       └── MokoAnimationController.swift
│   ├── Resources/
│   │   └── Animations/              # Lottie JSON files
│   │       ├── MokoHello.json
│   │       ├── MokoMeditation.json
│   │       ├── MocoListening.json
│   │       ├── MokoComplete.json
│   │       └── MokoIdle.json
│   ├── Moko/
│   │   ├── ContentView.swift
│   │   ├── MokoApp.swift
│   │   └── ...                      # Existing app code
│   └── UIScreens/
│       ├── startScreens/
│       │   └── ...                 # Screen files to integrate
│       └── relaxScreens/
│           └── ...                # More screen files
└── README.md                        # This file
```

---

## 🔧 Integration Checklist

### Lottie Setup
- [ ] Add Lottie iOS package via Package Dependencies (Option A) or Copy Items phase (Option B)
- [ ] Import `import Lottie` in views that need animations
- [ ] Copy all 5 JSON files to Xcode project resources

### Component Usage
- [ ] Replace existing placeholder mascot views with `MokoLottieView`
- [ ] Set correct animation names matching filenames
- [ ] Configure loop mode based on use case (loop vs once)
- [ ] Adjust frame width/height as needed for UI fit

### Screen Integration
- [ ] WelcomeScreen: Use `MokoHello` on first screen appearance
- [ ] MeditationScreen: Loop `MocoListening` with breathing sync
- [ ] CompletionScreen: Show `MocoComplete` after achievement event
- [ ] ListeningScreen: Display listening/talking states dynamically
- [ ] Overview/EmptyState: Default to `MokoIdle`

### Performance
- [ ] Set appropriate frame rate (30 FPS recommended)
- [ ] Optimize layer count (<5 for most animations)
- [ ] Test on multiple devices for smoothness
- [ ] Verify reduced motion accessibility compliance

---

## 🤖 Generated with Claude Code
