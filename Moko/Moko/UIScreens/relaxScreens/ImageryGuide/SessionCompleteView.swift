//
//  SessionCompleteView.swift
//  imageryGuide
//
//  Created by user@77 on 26/10/26.
//

import SwiftUI

struct SessionCompleteView: View {
    var message: String = "You took a moment to slow down, breathe, and imagine a place where you feel at peace."
    var onDone: () -> Void = {}

    private let accent = Color(hex: 0x365948)
    private let titleBrown = Color(hex: 0x5C4330)
    private let lime = Color(hex: 0xE2F5B1)

    var body: some View {
        VStack(spacing: 0) {
            Text("Imagery Guide")
                .font(.system(size: 24, weight: .semibold))
                .tracking(-0.4)
                .foregroundStyle(titleBrown)
                .padding(.top, 10)

            Text("Breathing and guided imagery paired together")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: 0x8A7B68))
                .padding(.top, 4)

            ZStack {
                Ellipse()
                    .fill(Color.white.opacity(0.72))
                    .frame(width: 259, height: 250)

                Circle()
                    .fill(lime.opacity(0.62))
                    .frame(width: 220, height: 220)

                MokoLottieView(animationType: .complete, size: 210)
            }
            .padding(.top, 35)

            Text("You did it!")
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.4)
                .foregroundStyle(titleBrown)
                .padding(.top, 97)

            Text(message)
                .font(.system(size: 18, weight: .light))
                .lineSpacing(12)
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 52)
                .padding(.top, 42)

            Spacer(minLength: 24)

            Button(action: onDone) {
                Text("Done")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 244, height: 61)
                    .background(accent, in: Capsule())
            }
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: 0xF6FAE8).ignoresSafeArea())
    }
}

#Preview {
    SessionCompleteView()
}
