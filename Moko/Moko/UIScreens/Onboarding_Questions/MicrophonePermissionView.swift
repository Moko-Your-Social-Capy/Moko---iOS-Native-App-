import SwiftUI
import AVFoundation

struct MicrophonePermissionView: View {
    let onContinue: () -> Void
    @State private var isRequesting = false
    @State private var permissionMessage: String?

    private let reason = "Moko uses your mic only when you record a voice reflection. You choose when it starts and you can delete recordings any time."

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Image("profile_empty_moko")
                .resizable()
                .scaledToFit()
                .frame(width: 164, height: 164)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "headphones")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x1F7488))
                        .padding(12)
                        .background(Color(hex: 0xF7F5F2), in: Circle())
                }
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Moko wearing headphones")

            Text("Let Moko listen")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: 0x4A3826))
                .padding(.top, 28)
            Text(reason)
                .font(.body)
                .foregroundStyle(Color(hex: 0x4A3826).opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
            Text("You can also use text reflections. Moko works without microphone access.")
                .font(.subheadline)
                .foregroundStyle(Color(hex: 0x4A3826).opacity(0.72))
                .padding(.top, 14)
            if let permissionMessage {
                Text(permissionMessage)
                    .font(.footnote)
                    .foregroundStyle(Color(hex: 0xB9583F))
                    .padding(.top, 10)
            }
            Spacer()
            Button(action: requestMicrophone) {
                HStack {
                    Spacer()
                    if isRequesting {
                        MokoFlossLoadingView(size: 30)
                            .frame(width: 30, height: 30)
                    }
                    else { Text("Allow microphone").fontWeight(.semibold) }
                    Spacer()
                }.frame(minHeight: 52)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: 0x1F7488))
            .buttonBorderShape(.capsule)
            .disabled(isRequesting)

            Button("Skip for now", action: onContinue)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color(hex: 0x4A3826))
                .frame(maxWidth: .infinity, minHeight: 50)
                .contentShape(Rectangle())
                .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(hex: 0xF7F5F2).ignoresSafeArea())
    }

    private func requestMicrophone() {
        isRequesting = true
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                isRequesting = false
                if granted {
                    onContinue()
                } else {
                    permissionMessage = "Microphone access is off. You can continue with text reflections."
                }
            }
        }
    }
}

struct AccountDeletedConfirmation: View {
    let onContinue: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color(hex: 0x2F6E4A))
            Text("Your account was deleted")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: 0x4A3826))
            Text("Your account and local Moko data have been removed.")
                .font(.body)
                .foregroundStyle(Color(hex: 0x4A3826).opacity(0.78))
            Spacer()
            Button(action: onContinue) {
                Text("Continue").fontWeight(.semibold).frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: 0x1F7488))
            .buttonBorderShape(.capsule)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(hex: 0xF7F5F2).ignoresSafeArea())
    }
}
