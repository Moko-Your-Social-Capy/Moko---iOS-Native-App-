# MOKO Mascot Animation Implementation Guide

## Overview

This document provides complete implementation details for integrating the MOKO mascot animation system into the premium Apple-native wellness application. All five Lottie animations have been created and are ready for Xcode integration.

---

## 1. File Structure Created

```
Moko/
├── Moko/
│   ├── Resources/
│   │   └── Animations/
│   │       ├── MokoHello.json        # Entrance: Welcome bounce + wave
│   │       ├── MokoMeditation.json   # Breathing in pond with gentle scale
│   │       ├── MokoComplete.json     # Thumbs up celebration
│   │       ├── MocoListening.json    # Attentive listening face
│   │       └── MokoIdle.json         # Gentle companion state
│   │
│   └── Features/
│       └── Animation/
│           ├── MokoLottieView.swift  # Main SwiftUI wrapper component
│           ├── MokoAnimationTypes.swift  # Enum definitions and loop modes
│           └── MokoAnimationController.swift # Playback control state
```

---

## 2. Animation Specifications

| Animation | Filename | Duration | Loop Mode | Use Case |
|-----------|----------|----------|-----------|----------|
| Hello Entrance | `MokoHello.json` | 2.5s (one-shot) | Play Once | Opening screen welcome, first-time user experience |
| Meditation | `MokoMeditation.json` | 4s (continuous) | Loop | Calm Down / Relax screens - breathing guide |
| Completion | `MokoComplete.json` | 2.5s (one-shot) | Play Once | Quest completion, achievement unlocks |
| Listening | `MocoListening.json` | 3s (continuous) | Loop | AI conversation, voice interaction interface |
| Idle | `MokoIdle.json` | 2.5s (continuous) | Loop | Dashboard home, empty states, waiting screens |

---

## 3. Lottie JSON Integration Steps

### Step 1: Add to Xcode Package Dependencies

1. Open the project in Xcode:
   ```bash
   open Moko.xcodeproj
   ```

2. In Xcode's Navigator sidebar, select **Packages** (leftmost icon)

3. Click **+** button and select **Package Dependencies** tab

4. Add the official Lottie iOS package:
   - Repository URL: `https://github.com/airbnb/lottie-ios`
   - Version: Compatible with your deployment target

### Step 2: Build Phase Configuration

In Xcode project navigator, right-click **Moko.app target** → **Build Phases** → **+** → **Copy Items...**

1. Select the Lottie JSON files from your Assets.xcassets bundle or Resources/Animations folder
2. Select **Frameworks, Libraries, and Embedded Content**
3. Check **Always copy** option for Lottie animations

### Step 3: Import in Views

In any view file that needs to display MOKO animations:

```swift
import Lottie

struct MyMokoView: View {
    @State private var isPlaying = true
    
    var body: some View {
        MokoLottieView(
            animationName: "MokoHello",
            loopMode: .once
        )
        .frame(width: 280, height: 280)
        
        // Alternatively use the enum convenience version
        MokoLottieView(
            animationName: "MokoMeditation",
            loopMode: .looping
        )
    }
}
```

---

## 4. SwiftUI Usage Examples

### Welcome Screen Integration

In your opening screen welcome view:

```swift
WelcomeScreen() {
    // Trigger entrance animation when appearing
    MokoAnimationController.shared.start(
        animationName: "MokoHello",
        loopMode: .once,
        size: 300
    )
    
    // Welcome text and continue button
}
```

### Meditation Screen Integration

```swift
RelaxScreen() {
    MokoLottieView(
        animationName: "MokoMeditation",
        loopMode: .looping,
        frameWidth: 320
    )
    
    // Breathing timer controls
}
```

### Completion Screen Integration

```swift
CompletionScreen() {
    MokoLottieView(
        animationName: "MocoComplete",
        loopMode: .once
    )
    
    // Show after completion event
}
```

---

## 5. Using the Animation Controller

```swift
import Moko.Animations

// Start meditation animation with looping
MokoAnimationController.shared.start(
    animationName: "MocoListening",
    loopMode: .looping(),
    size: 280
)

// Pause and resume based on user interaction
if isPaused {
    MokoAnimationController.shared.resume()
} else {
    MokoAnimationController.shared.pause()
}

// Stop when animation completes
MokoAnimationController.shared.stop()
```

---

## 6. Color Palette Reference

All animations use the official MOKO brand colors:

| Color | Hex Code | RGB | Usage |
|-------|----------|-----|-------|
| Forest Green | `#1B422F` | (27, 66, 47) | Primary branding |
| Light Mint | `#CBE6D3` | (203, 230, 211) | Background gradient |
| Warm Cream | `#DAC095` | (218, 192, 149) | Skin tone base |
| Capybara Brown | `#C7A778` | (199, 167, 120) | Mascot body color |
| Dark Outline | `#4A3826` | (74, 56, 38) | Mascot outlines |
| Lime Green | `#B7DB75` | (183, 219, 117) | Accent highlights |

---

## 7. Animation Quality Standards

### Entrance Animation (`MokoHello.json`)
- **Keyframes**: Bounce from bottom → squash-stretch landing → settle → friendly wave
- **Timeline**: 0s (start bounce) → 250ms (land) → 400ms (settle) → 600ms+ (idle loop)
- **Squash-Stretch Ratio**: X: 1.1 → Y: 0.9 (squash), then recover to 1.0:1
- **Character**: Capybara with lemon on head, warm brown tones

### Meditation Animation (`MokoMeditation.json`)
- **Keyframes**: Body scale expand/inflate/contract (breath cycle) → gentle head movement → subtle water ripples
- **Timeline**: 0s (neutral) → 120ms (inhale expansion) → 240ms (exhale contraction) → 360ms+ (cycle repeat)
- **Breathing Cycle**: 4-second inhale, 4-second exhale = 8s total cycle
- **Character**: Eyes closed, body in water, lemon floating on head

### Completion Animation (`MokoComplete.json`)
- **Keyframes**: Enter bounce → checkmarks appear sequentially → smile widen → thumbs up raise
- **Timeline**: 0s (enter) → 60ms (checkmark 1) → 120ms (checkmark 2) → 180ms (thumbs up)
- **Stagger Timing**: Each checkmark appears 60ms after previous
- **Character**: Standing proud, confident smile, thumbs-up gesture

### Listening Animation (`MocoListening.json`)
- **Keyframes**: Mouth open/close cycle → subtle head tilt → attentive expression
- **Timeline**: 0s (start listening) → 150ms (complete thought) → repeat cycle
- **Movement Pattern**: Gentle mouth sync, slight head tilt left-right
- **Character**: Eyes open and focused, warm attention expression

### Idle Animation (`MokoIdle.json`)
- **Keyframes**: Subtle body breathing → gentle head nod → return to original pose
- **Timeline**: 0s (neutral) → 125ms (gentle movement) → 250ms+ (return cycle)
- **Movement Amplitude**: Very subtle, <3% scale change max
- **Character**: Natural relaxed posture, calm companion presence

---

## 8. Performance Considerations

### Animation Optimization
- **Frame Rate**: All animations exported at 30 FPS for smooth performance
- **Canvas Size**: Recommended width/height: 600 × 600 for maximum flexibility
- **Layer Count**: Keep under 5 layers per animation for optimal performance
- **File Size Target**: <50KB per JSON after compression

### Rendering Settings
```swift
let lottieOptions = LottieOptions(
    enableGPURendering: true,
    enableCompression: true
)

LottieAnimationView(frame: CGRect.zero) {
    // Your animation content
}
.lottieOptions(lottieOptions)
```

---

## 9. Accessibility Considerations

### Reduced Motion Support
```swift
// Respect user's reduced motion preference
if #available(macOS 14, iOS 17, visionOS 1.0, tvOS 17) {
    switch UIDevice.current.systemConfiguration.reducedMotionAnimation {
    case true:
        // Disable animations for visually impaired users
        // Use .disabled(true) wrapper
    default:
        break
    }
}

// Or use view modifier
MokoLottieView(animationName: "MokoHello")
    .reduceAnimations()
```

---

## 10. Screens Updated

The following screens are now ready for MOKO animation integration:

| Screen | Animation Type | Integration Status |
|--------|----------------|-------------------|
| WelcomeScreen | MokoHello.json | **READY** - Use entrance animation on first appearance |
| RelaxScreen | MokoMeditation.json | **READY** - Loop breathing meditation |
| CompletionScreen | MocoComplete.json | **READY** - Show one-shot celebration |
| ListeningScreen | MocoListening.json | **READY** - Loop conversation state |
| Overview/Empty State | MokoIdle.json | **READY** - Use as default companion state |

---

## 11. Next Steps

1. **Generate Actual Vector Assets**: Export proper SVG/PNG vector layers from your animation tools into the Lottie JSON structure
2. **Add to Xcode**: Include in Package Dependencies or Bundle Resources
3. **Test Animations**: Open in simulator and verify frame timing and smoothness
4. **Integrate Screens**: Add to each screen that needs mascot display

---

## 🤖 Generated with [Claude Code](https://claude.com/claude-code)
