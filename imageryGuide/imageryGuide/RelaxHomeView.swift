//
//  RelaxHomeView.swift
//  imageryGuide
//
//  Created by user@77 on 26/10/26.
//

import SwiftUI

/// Placeholder for the Relax home screen. Replace the body with your real
/// design; keep the `onSelectImageryGuide` call on the Imagery Guide item.
struct RelaxHomeView: View {
    var onSelectImageryGuide: () -> Void = {}

    private let accent   = Color(hex: 0x365948)
    private let tileFill = Color(hex: 0xE6EFE9)
    private let ink      = Color(hex: 0x2F2A28)
    private let subtitle = Color(hex: 0x8A7B68)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Relax")
                .font(.system(size: 26, weight: .semibold))
                .tracking(-0.4)
                .foregroundStyle(ink)
                .padding(.top, 16)

            Text("Choose a way to unwind")
                .font(.system(size: 13))
                .foregroundStyle(subtitle)
                .padding(.top, 8)

            Button(action: onSelectImageryGuide) {
                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(tileFill)
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: "figure.mind.and.body")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(accent)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Imagery Guide")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(ink)
                        Text("Breathing and guided imagery paired together")
                            .font(.system(size: 13))
                            .foregroundStyle(subtitle)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(subtitle)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white)
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 28)

            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(hex: 0xF2F2F7).ignoresSafeArea())
    }
}

#Preview {
    RelaxHomeView()
}
