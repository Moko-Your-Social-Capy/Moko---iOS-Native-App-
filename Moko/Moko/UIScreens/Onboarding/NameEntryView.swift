import SwiftUI

struct NameEntryView: View {
    var progress: CGFloat = 0.677
    var onBack: () -> Void = {}
    var onContinue: (String) -> Void = { _ in }

    @State private var name = ""
    @FocusState private var isFocused: Bool

    private let placeholderColor = Color(hex: 0xD2C6B3)

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var canContinue: Bool { !trimmedName.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            header

            Text("What should we call you?")
                .font(.system(size: 30, weight: .bold))
                .tracking(-0.5)
                .foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 24)

            nameField
                .padding(.horizontal, 30)
                .padding(.top, 35)

            Spacer()

            continueButton
                .padding(.horizontal, 20)
                .padding(.bottom, 38)
        }
        .background(Color.white.ignoresSafeArea())
        .contentShape(Rectangle())
        .task { isFocused = true }
    }

    // MARK: Header (back button + progress bar)

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

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.track)
                    Capsule().fill(Color.forestLight)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 3)
        }
        .padding(.horizontal, 20)
    }

    // MARK: Name field

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your Name")
                .font(.system(size: 15))
                .foregroundStyle(Color.ink)

            TextField(
                "",
                text: $name,
                prompt: Text("e.g. John").foregroundStyle(placeholderColor)
            )
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(Color.ink)
            .tint(Color.forest)
            .focused($isFocused)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.continue)
            .onSubmit(submit)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
    }

    // MARK: Continue button

    private var continueButton: some View {
        Button(action: submit) {
            HStack(spacing: 8) {
                Text("Continue")
            }
            .font(.system(size: 17))
            .foregroundStyle(Color.cream)
            .frame(maxWidth: .infinity)
            .frame(height: 50.5)
            .background(Color.forest, in: Capsule())
            .opacity(canContinue ? 1 : 0.4)
        }
        .disabled(!canContinue)
        .animation(.easeInOut(duration: 0.15), value: canContinue)
    }

    private func submit() {
        guard canContinue else { return }
        onContinue(trimmedName)
    }
}

#Preview {
    NameEntryView(onContinue: { print("Name:", $0) })
}
