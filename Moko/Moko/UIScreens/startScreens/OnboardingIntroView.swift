//
//  OnboardingIntroView.swift
//  Moko
//
//  The welcome screen after the splash: the mascot says hello,
//  a short line explains the app, and "Let's Begin" starts sign-in.
//

import SwiftUI

struct OnboardingIntroView: View {
    /// Called when the user taps "Let's Begin".
    var onLetsBegin: () -> Void = {}

    // False at the start, true once the text and button have faded in.
    @State private var hasAppeared = false

    // The phone setting "Reduce Motion". If it is on, text fades but does not slide.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // GeometryReader gives us the screen width, so the mascot fits small phones too.
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer(minLength: 20)

                MokoAnimatedMascotView(size: min(geometry.size.width * 0.62, 250))
                    .padding(.bottom, 16)

                Text("Hello, I’m Moko.")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(MokoScreenTheme.Colors.dataVioletDeep)
                    .padding(.horizontal, MokoScreenTheme.Space.page)
                    .modifier(RiseIn(isVisible: hasAppeared, distance: 12, reduceMotion: reduceMotion))

                Text("Small daily nudges, an honest chat\nafter, that's it!")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(MokoScreenTheme.Colors.textBody)
                    .lineSpacing(4)
                    .padding(.top, 12)
                    .padding(.horizontal, 32)
                    .modifier(RiseIn(isVisible: hasAppeared, distance: 16, reduceMotion: reduceMotion))

                Spacer(minLength: 40)

                letsBeginButton
                    .padding(.horizontal, MokoScreenTheme.Space.page)
                    .padding(.bottom, 20)
                    .modifier(RiseIn(isVisible: hasAppeared, distance: 20, reduceMotion: reduceMotion))
            }
            .multilineTextAlignment(.center)
            // Phones without a notch or home bar get a little extra breathing room.
            .padding(.top, geometry.safeAreaInsets.top > 0 ? 0 : 16)
            .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(MokoScreenTheme.Colors.tileLilac.ignoresSafeArea())
            // .onAppear runs when the screen first shows. It starts the fade-in.
            .onAppear {
                withAnimation(MokoScreenTheme.Motion.crossfade) {
                    hasAppeared = true
                }
            }
        }
    }

    private var letsBeginButton: some View {
        Button {
            // A small tap you can feel, so the button feels pressed.
            MokoTheme.playFeedback(.medium)
            onLetsBegin()
        } label: {
            Text("Let's Begin")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(MokoScreenTheme.Colors.dataVioletDeep, in: Capsule())
        }
        .buttonStyle(MokoPrimaryButtonStyle())
    }
}

/// Fades a view in and lifts it up a few points. With Reduce Motion it only fades.
private struct RiseIn: ViewModifier {
    let isVisible: Bool
    let distance: CGFloat
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible || reduceMotion ? 0 : distance)
    }
}

#Preview {
    OnboardingIntroView()
}
