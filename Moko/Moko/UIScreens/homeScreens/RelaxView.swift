//
//  RelaxView.swift
//  Moko
//
//  Relaxation and breathing screen with floating MokoTabBar.
//

import SwiftUI

struct RelaxView: View {
    @Binding var selectedTab: MokoTab

    private let screenBg = Color(red: 242/255, green: 242/255, blue: 247/255) // #F2F2F7
    private let primaryGreen = Color(red: 27/255, green: 66/255, blue: 47/255) // #1B422F
    private let titleDark = Color(red: 47/255, green: 42/255, blue: 40/255) // #2F2A28
    private let subtextGray = Color(red: 111/255, green: 103/255, blue: 98/255) // #6F6762

    @State private var isBreatingActive = false
    @State private var breathText = "Inhale..."

    var body: some View {
        ZStack(alignment: .bottom) {
            screenBg
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // MARK: - Header
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 14)

                    // MARK: - Relax / Breathing Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Daily Calm")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(titleDark)

                        Text("Take a moment to center yourself. Follow the breathing guide to calm your nervous system.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(subtextGray)
                            .lineSpacing(4)

                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(primaryGreen.opacity(0.08))
                                .frame(height: 220)

                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(primaryGreen.opacity(0.2))
                                        .frame(width: isBreatingActive ? 120 : 80, height: isBreatingActive ? 120 : 80)
                                        .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: isBreatingActive)

                                    Image(systemName: "figure.mind.and.body")
                                        .font(.system(size: 36, weight: .semibold))
                                        .foregroundColor(primaryGreen)
                                }

                                Text(breathText)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(primaryGreen)

                                Button(action: {
                                    isBreatingActive.toggle()
                                    breathText = isBreatingActive ? "Exhale slowly..." : "Inhale deeply..."
                                }) {
                                    Text(isBreatingActive ? "Pause" : "Start Breathing")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(primaryGreen)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.top, 12)
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
                    .padding(.top, 28)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 120)
                }
            }

            // MARK: - Floating Tab Bar
            MokoTabBar(selectedTab: $selectedTab)
                .padding(.bottom, 4)
        }
    }

    private var headerSection: some View {
        HStack(alignment: .center) {
            Text("Relax")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.black)

            Spacer()

            ZStack {
                Circle()
                    .fill(Color(red: 68/255, green: 68/255, blue: 68/255).opacity(0.6))
                    .frame(width: 47, height: 47)

                Text("AJ")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    RelaxView(selectedTab: .constant(.relax))
}
