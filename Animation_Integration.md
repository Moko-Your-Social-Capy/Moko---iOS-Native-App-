# MOKO Lottie Animation Integration Instructions

## Quick Start

This guide walks you through integrating the 5 Lottie animations created for the MOKO mascot system.

---

## Table of Contents

1. [Adding Lottie Package](#adding-lottie-package)
2. [File Locations](#file-locations)
3. [SwiftUI Usage Examples](#swiftui-usage-examples)
4. [Integrate with Screens](#integrate-with-screens)
5. [Testing and Verification](#testing-and-verification)

---

## 1. Adding Lottie Package

### Option A: Swift Package Manager (Recommended)

1. **Open Xcode**
   ```bash
   cd /Users/user42/Documents/Moko---iOS-Native-App-/Moko
   open Moko.xcodeproj
   ```

2. **In Xcode**, select **Package Dependencies** tab (left sidebar icon ⚡)

3. **Click the "+" button** and choose "Add Package" tab

4. **Enter URL**:
   ```
   https://github.com/airbnb/lottie-ios
   ```

5. **Select version**: Compatible with your deployment target
   - For iOS 16.0+ use version `~> 3.0`
   - For iOS 15.0+ use version `~> 2.0`

6. **Add to project** and rebuild

7. **Import in source files**:
   ```swift
   import Lottie
   ```

### Option B: Copy JSON Files

1. In Xcode, select **Project Navigator → Your Target → General → "Copy Items"** phase

2. **Drag the 5 JSON files** from this folder:
   ```
   Moko/Moko/Resources/Animations/
   ```
   into the copy items list

3. **Select** "Copy built files to Products directory"

4. Rebuild and import in source files as above

---

## 2. File Locations

```
Moko/
├── Moko/
│   ├── Resources/
│   │   └── Animations/
│   │       ├── MokoHello.json          # Welcome entrance
│   │       ├── MokoMeditation.json     # Breathing meditation
│   │       ├── MocoListening.json      # Listening state
│   │       ├── MokoComplete.json       # Celebration thumbs-up
│   │       └── MokoIdle.json           # Gentle companion state
│   │
│   └── Features/
│       └── Animation/
│           ├── MokoLottieView.swift    # SwiftUI wrapper component
│           ├── MokoAnimationTypes.swift # Enum definitions
│           └── MokoAnimationController.swift # Playback control
```

---

## 3. SwiftUI Usage Examples

### Basic Lottie Integration

```swift
import Lottie

struct MyView: View {
    var body: some View {
        MokoLottieView(
            animationName: "MokoHello",
            loopMode: .once
        )
        .frame(width: 280, height: 280)
    }
}
```

### Using Convenience Functions

```swift
struct MyView: View {
    var body: some View {
        MokoMascotView(
            animationName: "MocoListening",
            loopMode: .looping
        )
        .frame(width: 280)
    }
}
```

### With Color Backgrounds

```swift
MokoLottieView(
    animationName: "MokoIdle"
)
.background(.ultraThinMaterial)
.frame(width: 300, height: 300)
.padding()
```

---

## 4. Integrate with Screens

### Welcome Screen Integration

In `UIScreens/startScreens/WelcomeView.swift`:

```swift
struct WelcomeView: View {
    @Environment(\.animation) var animation
    
    var body: some View {
        ZStack {
            Color.limeGreen
            
            MokoLottieView(
                animationName: "MokoHello",
                loopMode: .once,
                frameWidth: 300
            )
            .onAppear {
                // Animation plays when view appears
                // Set autoPlay = true for entrance effect
            }
            
            Text("Welcome to MOKO")
                .font(.largeTitle)
        }
    }
}
```

### Meditation Screen Integration

In `UIScreens/relaxScreens/Breathing/Breathingsessionscreen.swift`:

```swift
struct Breathingsessionscreen: View {
    @StateObject private var isBreathing = true
    
    var body: some View {
        VStack(spacing: 0) {
            MokoLottieView(
                animationName: "MokoMeditation",
                loopMode: .looping,
                frameWidth: 320
            )
            
            Text("Breathe with me")
                .monospacedDigitFont()
        }
    }
}
```

### Listening Screen Integration

In `UIScreens/startScreens/ListeningScreen.swift`:

```swift
struct ListeningScreen: View {
    @Environment(\.isSpeaking) var isSpeaking
    
    var body: some View {
        MokoLottieView(
            animationName: "MocoListening",
            loopMode: .looping,
            frameWidth: 280
        )
        
        Text("I'm here for you")
    }
}
```

---

## 5. Testing and Verification

### Create Preview Test File

In `AnimationScripts/PreviewTest.swift`:

```swift
#Preview {
    MokoLottieView(
        animationName: "MokoHello"
    )
    .frame(width: 200, height: 200)
    .padding()
}
```

### Verify Frame Timing

Open each JSON file and check the "frames" section for timing values.

Example (MokoHello.json):
```json
{
  "frames": {
    "0": {"time": 0},
    "1": {"time": 483.33},
    "2": {"time": 966.67}
  }
}
```
- Frame at 0s = Start of bounce
- Frame at ~8s = Landing settled

### Quality Checklist

- [ ] Animations render smoothly in SwiftUI
- [ ] Loop behavior works as expected (loop vs playOnce)
- [ ] Character identity is consistent across all files
- [ ] Lemon accessory appears correctly in meditation scene
- [ ] Thumbs-up gesture is visible and animated properly

---

## 6. Common Issues & Solutions

### Issue: Animation doesn't load

**Solution**: Ensure Lottie package is added via Package Dependencies or copy phase

```swift
import Lottie // Must be imported at top of file
```

### Issue: Frame timing looks jerky

**Solution**: Adjust frame rate in JSON files

```json
{
  "frameRate": 60 // Increase for smoother animation
}
```

### Issue: Character looks distorted

**Solution**: Check layer bounds and transform values match original art

---

## 🤖 Generated with [Claude Code](https://claude.com/claude-code)
