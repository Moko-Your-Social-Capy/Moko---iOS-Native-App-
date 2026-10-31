import SwiftUI

struct ImageryGuideDetailView: View {
    let guide: ImageryGuide

    private let accent = Color(hex: 0x365948)
    private let tileFill = Color(hex: 0xE2F5B1)
    private let ink = Color(hex: 0x5C4330)
    private let bodyText = Color(hex: 0x51443E)
    private let subtitle = Color(hex: 0x8A7B68)
    private let caption = Color(hex: 0x6F6762)

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Imagery Guide")
                    .font(.system(size: 26, weight: .semibold))
                    .tracking(-0.4)
                    .foregroundStyle(ink)

                Text(guide.detailHeaderSubtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(subtitle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 19)

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .frame(width: 140, height: 140)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(tileFill)
                        .frame(width: 120, height: 120)
                        .overlay {
                            Image(systemName: guide.icon)
                                .font(.system(size: 46, weight: .semibold))
                                .foregroundStyle(accent)
                        }
                }
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

            NavigationLink(value: RelaxRoute.guideSession(guide)) {
                Text("Start")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 244, height: 61)
                    .background(accent, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 66)

            Text("About 2 minutes · pause any time")
                .font(.system(size: 15))
                .tracking(0.3)
                .foregroundStyle(caption)
                .padding(.top, 20)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: 0xF6FAE8).ignoresSafeArea())
        .navigationTitle("Imagery Guide")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ImageryGuideDetailView(guide: ImageryGuide.all[0])
    }
}
