import SwiftUI

struct WelcomeView: View {
    let name: String                       // the name the user typed earlier
    var onBack: () -> Void = {}
    var onStart: () -> Void = {}

    private var greeting: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Nice to meet you" : "Nice to meet you, \(trimmed)"
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Text(greeting)
                .font(.system(size: 25, weight: .semibold))
                .tracking(-0.3)
                .foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 57)

            Text("Moko has a few quick questions to personalize your daily practice.")
                .font(.system(size: 17))
                .lineSpacing(3)
                .foregroundStyle(Color.ink)
                .frame(maxWidth: 300, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 32)

            Image("welcome_moko")
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 20)
                .padding(.top, 60)

            Spacer(minLength: 16)

            startButton
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
        }
        .background(Color.white.ignoresSafeArea())
    }

    // MARK: Header (back button + full progress bar)

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.ink)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Capsule()
                .fill(Color.forestLight)
                .frame(height: 3)
        }
        .padding(.horizontal, 20)
    }

    // MARK: Start button

    private var startButton: some View {
        Button(action: onStart) {
            HStack(spacing: 8) {
                Text("Start reflections")
                Image(systemName: "arrow.right")
            }
            .font(.system(size: 17))
            .foregroundStyle(Color.cream)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.forest, in: Capsule())
        }
    }
}

#Preview {
    WelcomeView(name: "Aditi")
}
