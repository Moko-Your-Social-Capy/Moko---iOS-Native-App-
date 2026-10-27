//
//  ImageryGuideView.swift
//  imageryGuide
//
//  Created by user@77 on 26/10/26.
//

import SwiftUI

/// The Imagery Guide intro card. It is shown as a native iOS sheet
/// (see RelaxFlow), so the sheet itself provides the rounded top corners,
/// the dimmed page behind it and swipe-down-to-close.
struct ImageryGuideView: View {
    var onContinue: () -> Void = {}
    var onNotNow: () -> Void = {}

    private let sage = Color(hex: 0x365948)
    private let bodyText = Color(hex: 0x6F6762)

    var body: some View {
        VStack(spacing: 0) {
            // Illustration
            Color.clear
                .frame(height: 320)
                .overlay(
                    Image("imagery_guide")
                        .resizable()
                        .scaledToFill()
                )
                .clipped()

            Text("Imagery Guide")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.primary)
                .padding(.top, 20)

            Spacer(minLength: 24)

            Text("Close your eyes and imagine a peaceful place or happy memory. Picture the sights, sounds, and feelings around you. Breathe slowly and let your mind relax.")
                .font(.system(size: 17))
                .lineSpacing(3)
                .foregroundStyle(bodyText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)

            Spacer(minLength: 24)

            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 61)
                    .background(sage, in: Capsule())
            }
            .padding(.horizontal, 35)

            Button(action: onNotNow) {
                Text("Not now")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(sage)
                    .padding(.vertical, 8)
            }
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    ImageryGuideView()
}
