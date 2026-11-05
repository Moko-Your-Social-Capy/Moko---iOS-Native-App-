import SwiftUI

struct WelcomeView: View {
    let name: String                       // the name the user typed earlier
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
        .background(AppBackground())
    }

    // MARK: Header (full progress bar)

    private var header: some View {
        Capsule()
            .fill(Color.forestLight)
            .frame(height: 3)
            .padding(.horizontal, 20)
    }

    // MARK: Start button

    private var startButton: some View {
        Button(action: onStart) {
            HStack(spacing: 8) {
                Text("Start reflections")
            }
            .font(.system(size: 17))
            .foregroundStyle(Color.cream)
            .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(hex: 0x1F7488), in: Capsule())
        }
            .buttonStyle(MokoPrimaryButtonStyle())
            .shadow(color: Color(hex: 0x1F7488).opacity(0.18), radius: 8, y: 4)
    }
}

#Preview {
    WelcomeView(name: "Aditi")
}
