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
    private let cream  = Color(hex: 0xF7EEDD)

    var body: some View {
        VStack(spacing: 0) {
            Text("Imagery Guide")
                .font(.system(size: 24, weight: .semibold))
                .tracking(-0.4)
                .foregroundStyle(Color(hex: 0x292B26))
                .padding(.top, 10)

            Text("Breathing and guided imagery paired together")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: 0x8A7B68))
                .padding(.top, 4)

            // Check badge
            ZStack {
                Ellipse()
                    .fill(Color.white)
                    .frame(width: 259, height: 250)

                Circle()
                    .fill(accent)
                    .frame(width: 200, height: 200)

                Circle()
                    .stroke(cream, lineWidth: 12)
                    .frame(width: 87, height: 87)

                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundStyle(cream)
            }
            .padding(.top, 35)

            Text("You did it!")
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.4)
                .foregroundStyle(.black)
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
        .background(Color(hex: 0xF2F2F7).ignoresSafeArea())
    }
}

#Preview {
    SessionCompleteView()
}
