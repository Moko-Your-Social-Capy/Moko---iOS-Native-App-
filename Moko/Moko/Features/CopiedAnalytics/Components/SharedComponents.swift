import SwiftUI

struct MokoPeriodPicker: View {
    @Binding var selection: MokoPeriod

    var body: some View {
        Picker("Period", selection: $selection) {
            ForEach(MokoPeriod.allCases) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .tint(AppColors.forest)
        .accessibilityLabel("Choose Day, Week, or Month")
    }
}

struct ScreenTitle: View {
    let title: String
    var showsBack: Bool = false
    var backAction: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            if showsBack {
                Button { backAction?() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppColors.forest)
                        .frame(width: 30, height: 30)
                        .background(AppColors.card, in: Circle())
                }
                .buttonStyle(.plain)
            }
            Text(title).font(.system(size: 24, weight: .bold, design: .rounded))
            Spacer()
        }
    }
}

struct SurfaceCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
