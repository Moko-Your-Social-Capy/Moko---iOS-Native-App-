//
//  ImageryGuideDetailView.swift
//  imageryGuide
//
//  Created by user@77 on 26/10/26.
//

import SwiftUI

struct ImageryGuideDetailView: View {
    let guide: ImageryGuide
    var onStart: () -> Void = {}

    private let accent   = Color(hex: 0x365948)
    private let tileFill = Color(hex: 0xE6EFE9)
    private let ink      = Color(hex: 0x2F2A28)
    private let bodyText = Color(hex: 0x51443E)
    private let subtitle = Color(hex: 0x8A7B68)
    private let caption  = Color(hex: 0x6F6762)

    var body: some View {
        VStack(spacing: 0) {
            // Header (left aligned)
            VStack(alignment: .leading, spacing: 8) {
                Text("Imagery Guide")
                    .font(.system(size: 26, weight: .semibold))
                    .tracking(-0.4)
                    .foregroundStyle(Color(hex: 0x292B26))

                Text(guide.detailHeaderSubtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(subtitle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 19)

            // Icon tile
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .frame(width: 140, height: 140)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(tileFill)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: guide.icon)
                                .font(.system(size: 46, weight: .semibold))
                                .foregroundStyle(accent)
                        )
                )
                .padding(.top, 74)

            Text(guide.title)
                .font(.system(size: 24, weight: .bold))
                .tracking(-0.4)
                .foregroundStyle(ink)
                .padding(.top, 11)

            Text(guide.detailDescription)
                .font(.system(size: 16))
                .lineSpacing(4.5)
                .foregroundStyle(bodyText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
                .padding(.top, 28)

            Button(action: onStart) {
                Text("Start")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 244, height: 61)
                    .background(accent, in: Capsule())
            }
            .padding(.top, 66)

            Text("About 2 minutes · pause any time")
                .font(.system(size: 15))
                .tracking(0.3)
                .foregroundStyle(caption)
                .padding(.top, 20)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: 0xF2F2F7).ignoresSafeArea())
    }
}

#Preview {
    ImageryGuideDetailView(guide: ImageryGuide.all[0])
}
