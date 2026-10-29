//
//  MirrorReflectionScreen.swift
//  Moko
//
//  Landing screen after "Continue" on the Mirror session.
//  Hero: a glowing arch mirror with a drawn face, then two options.
//

import SwiftUI

struct MirrorReflectionScreen: View {
    enum Option {
        case mirror
        case camera
    }

    /// Fires when the user picks one of the two options.
    var onSelectOption: ((Option) -> Void)? = nil
    /// Back button action. Defaults to dismissing the screen.
    var onBack: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    // Palette matching the rest of the app
    private let screenBg = Color(red: 242/255, green: 242/255, blue: 247/255)   // #F2F2F7
    private let cardGreen = Color(red: 54/255, green: 89/255, blue: 72/255)     // #365948
    private let titleDark = Color(red: 47/255, green: 42/255, blue: 40/255)     // #2F2A28
    private let subtextGray = Color(red: 111/255, green: 103/255, blue: 98/255) // #6F6762
    private let chipBg = Color(red: 237/255, green: 237/255, blue: 237/255)     // #EDEDED

    var body: some View {
        ZStack {
            screenBg.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    header
                        .padding(.horizontal, 24)
                        .padding(.top, 18)

                    MirrorHero()
                        .padding(.top, 28)

                    Text("Meet yourself with kindness")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(titleDark)
                        .multilineTextAlignment(.center)
                        .padding(.top, 28)
                        .padding(.horizontal, 24)

                    Text("Take a moment to look at yourself without judging. You don’t need to be perfect to be proud of who you are. Find one thing you appreciate about yourself and give yourself some credit.")
                        .font(.system(size: 15))
                        .foregroundColor(subtextGray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.top, 12)
                        .padding(.horizontal, 32)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Options")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(subtextGray)
                            .padding(.leading, 8)

                        optionRow("I have access to a mirror") {
                            onSelectOption?(.mirror)
                        }

                        optionRow("I want to continue with my camera") {
                            onSelectOption?(.camera)
                        }
                    }
                    .padding(.top, 30)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
        }
    }

    // MARK: - Top bar and header
    private var topBar: some View {
        HStack {
            Button {
                if let onBack {
                    onBack()
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(chipBg))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Mirror Reflection")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(titleDark)

            Text("A self-reflective confidence practice")
                .font(.system(size: 15))
                .foregroundColor(subtextGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Option row
    private func optionRow(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(titleDark)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(cardGreen)
            }
            .padding(.horizontal, 24)
            .frame(height: 58)
            .background(
                Capsule()
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: title)
    }
}

// MARK: - Hero: glowing arch mirror with a drawn face
struct MirrorHero: View {
    /// Show the "Meet Your Eyes" caption. Off for a larger face-only mirror.
    var showCaption: Bool = true
    /// 0...1: how bright the halo glows.
    var level: Double = 0.5

    @State private var glow = false
    @State private var sparkle = false

    private let frameTop = Color(red: 226/255, green: 238/255, blue: 229/255)
    private let frameBottom = Color(red: 200/255, green: 222/255, blue: 208/255)
    private let glassTop = Color(red: 253/255, green: 254/255, blue: 253/255)
    private let glassBottom = Color(red: 232/255, green: 243/255, blue: 236/255)
    private let green = Color(red: 54/255, green: 89/255, blue: 72/255)
    private let subtextGray = Color(red: 111/255, green: 103/255, blue: 98/255)

    var body: some View {
        ZStack {
            // Soft halo that gently pulses
            Circle()
                .fill(
                    RadialGradient(
                        colors: [green.opacity(0.10 + 0.20 * level), green.opacity(0)],
                        center: .center,
                        startRadius: 20,
                        endRadius: 170
                    )
                )
                .frame(width: 340, height: 340)
                .scaleEffect(glow ? 1.06 : 0.94)

            // Mirror frame
            RoundedRectangle(cornerRadius: 104, style: .continuous)
                .fill(LinearGradient(colors: [frameTop, frameBottom], startPoint: .top, endPoint: .bottom))
                .frame(width: 212, height: 282)
                .shadow(color: green.opacity(0.16), radius: 18, x: 0, y: 10)

            // Glass
            RoundedRectangle(cornerRadius: 88, style: .continuous)
                .fill(LinearGradient(colors: [glassTop, glassBottom], startPoint: .top, endPoint: .bottom))
                .frame(width: 176, height: 246)
                .overlay {
                    RoundedRectangle(cornerRadius: 88, style: .continuous)
                        .stroke(Color.white.opacity(0.9), lineWidth: 2)
                }
                // Light streaks across the glass
                .overlay {
                    ZStack {
                        Capsule()
                            .fill(Color.white.opacity(0.55))
                            .frame(width: 26, height: 260)
                            .rotationEffect(.degrees(24))
                            .offset(x: -42)
                        Capsule()
                            .fill(Color.white.opacity(0.4))
                            .frame(width: 9, height: 260)
                            .rotationEffect(.degrees(24))
                            .offset(x: -14)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 88, style: .continuous))
                }

            // Content inside the glass
            if showCaption {
                VStack(spacing: 8) {
                    MirrorFaceIcon()
                        .frame(width: 72, height: 72)

                    Text("Meet Your Eyes")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.top, 4)

                    Text("Quiet presence")
                        .font(.system(size: 12))
                        .foregroundColor(subtextGray)
                }
            } else {
                MirrorFaceIcon()
                    .frame(width: 72, height: 72)
                    .scaleEffect(1.7)
            }

            // Twinkles around the mirror
            Image(systemName: "sparkle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(green.opacity(0.55))
                .offset(x: 112, y: -112)
                .opacity(sparkle ? 1 : 0.25)
                .scaleEffect(sparkle ? 1 : 0.7)

            Image(systemName: "sparkle")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(green.opacity(0.45))
                .offset(x: -118, y: 84)
                .opacity(sparkle ? 0.25 : 1)
                .scaleEffect(sparkle ? 0.7 : 1)

            Image(systemName: "sparkle")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(green.opacity(0.4))
                .offset(x: 120, y: 70)
                .opacity(sparkle ? 1 : 0.3)
        }
        .frame(height: 300)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                glow = true
            }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                sparkle = true
            }
        }
    }
}

// MARK: - Simple friendly face (closed eyes, soft smile)
struct MirrorFaceIcon: View {
    private let disc = Color(red: 232/255, green: 243/255, blue: 236/255)
    private let skin = Color(red: 243/255, green: 206/255, blue: 182/255)
    private let hair = Color(red: 92/255, green: 62/255, blue: 48/255)
    private let cheek = Color(red: 236/255, green: 150/255, blue: 140/255)

    var body: some View {
        ZStack {
            Circle().fill(disc)

            // Hair bun
            Circle()
                .fill(hair)
                .frame(width: 16, height: 16)
                .offset(x: -16, y: -22)

            // Face
            Circle()
                .fill(skin)
                .frame(width: 40, height: 40)
                .offset(y: 4)

            // Hair cap
            Circle()
                .trim(from: 0.5, to: 1)
                .fill(hair)
                .frame(width: 42, height: 42)
                .offset(y: 3)

            // Cheeks
            Circle().fill(cheek.opacity(0.4)).frame(width: 8, height: 8).offset(x: -12, y: 12)
            Circle().fill(cheek.opacity(0.4)).frame(width: 8, height: 8).offset(x: 12, y: 12)

            // Closed eyes
            Circle()
                .trim(from: 0.05, to: 0.45)
                .stroke(hair, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                .frame(width: 9, height: 9)
                .offset(x: -8, y: 6)
            Circle()
                .trim(from: 0.05, to: 0.45)
                .stroke(hair, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                .frame(width: 9, height: 9)
                .offset(x: 8, y: 6)

            // Smile
            Circle()
                .trim(from: 0.12, to: 0.38)
                .stroke(hair, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                .frame(width: 16, height: 16)
                .offset(y: 11)
        }
    }
}

#Preview {
    MirrorReflectionScreen()
}