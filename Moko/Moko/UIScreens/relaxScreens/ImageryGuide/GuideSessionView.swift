//
//  GuideSessionView.swift
//  imageryGuide
//
//  Created by user@77 on 26/10/26.
//

import SwiftUI
import SwiftData
import Combine

struct GuideSessionView: View {
    let guide: ImageryGuide
    var onContinue: () -> Void = {}

    @Environment(ImageryGuideStore.self) private var store
    @State private var elapsed: TimeInterval = 0
    @State private var isRunning = true           // starts as soon as the screen opens
    @State private var lastTick = Date()
    @Environment(\.modelContext) private var modelContext

    private let ticker = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    private let accent   = Color(hex: 0x365948)
    private let tileFill = Color(hex: 0xE2F5B1)
    private let ink      = Color(hex: 0x5C4330)
    private let caption  = Color(hex: 0x6F6762)
    private let track    = Color(hex: 0xEDEDED)

    // MARK: Derived state

    private var screen: ImageryGuideScreenContent? { store.screen }
    private var totalSeconds: TimeInterval { TimeInterval(guide.durationSeconds) }
    private var steps: [String] { guide.sessionSteps.isEmpty ? [""] : guide.sessionSteps }
    private var isComplete: Bool { elapsed >= totalSeconds }

    private var stepIndex: Int {
        let perStep = totalSeconds / Double(steps.count)
        return min(Int(elapsed / perStep), steps.count - 1)
    }

    private var headerText: String {
        guard let screen else { return "" }
        if isComplete { return screen.sessionCompleteHeader }

        let step = screen.format(screen.sessionStepFormat, [
            "current": "\(stepIndex + 1)",
            "total": "\(steps.count)"
        ])
        return isRunning ? step : step + screen.sessionPausedSuffix
    }

    private var instruction: String {
        if isComplete {
            guard let screen else { return "" }
            return screen.format(screen.sessionCompleteInstructionFormat, [
                "duration": format(Int(totalSeconds))
            ])
        }
        return steps[stepIndex]
    }

    private func format(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    // MARK: Body

    var body: some View {
        ZStack(alignment: .bottom) {
            background

            panel
                .padding(.horizontal, 16)
                .padding(.bottom, 22)
        }
        .navigationTitle(guide.title)
        .navigationBarTitleDisplayMode(.inline)
        // Immersive session: give the guidance panel the full screen.
        .toolbar(.hidden, for: .tabBar)
        .task { await store.loadIfNeeded() }
        .onReceive(ticker) { date in
            let dt = min(date.timeIntervalSince(lastTick), 0.5)
            lastTick = date
            guard isRunning, !isComplete else { return }
            elapsed = min(totalSeconds, elapsed + dt)
            if elapsed >= totalSeconds {
                isRunning = false
                modelContext.logCalmDown("Imagery Guide", seconds: totalSeconds)
            }
        }
        .onDisappear { isRunning = false }
        .sensoryFeedback(.impact(weight: .light), trigger: stepIndex)
        .sensoryFeedback(.success, trigger: isComplete)
    }

    // MARK: Background photo

    private var background: some View {
        // Keep the photo in an overlay so its intrinsic size can never stretch
        // the session's layout beyond the screen edges.
        Color.clear
            .overlay {
                ZStack {
                    tileFill

                    if let url = guide.artworkURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .scaleEffect(guide.sessionImageScale, anchor: .top)
                                    .offset(x: guide.sessionImageShift)   // framing comes from Supabase
                            case .empty:
                                ProgressView()
                                    .tint(accent)
                            case .failure:
                                iconArtwork
                            @unknown default:
                                iconArtwork
                            }
                        }
                    } else {
                        iconArtwork
                    }
                }
            }
            .clipped()
            .ignoresSafeArea()
    }

    private var iconArtwork: some View {
        Image(systemName: guide.icon)
            .font(.system(size: 140, weight: .semibold))
            .foregroundStyle(accent.opacity(0.35))
    }

    // MARK: Guidance panel

    private var panel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Step label + subtle controls
            HStack {
                Text(headerText)
                    .font(.system(size: 12, weight: .bold))
                    .tracking(0.3)
                    .foregroundStyle(caption)
                Spacer()
                if !isComplete { controls }
            }
            .frame(height: 32)

            // Instruction (cross-fades when it changes)
            ZStack(alignment: .topLeading) {
                Text(instruction)
                    .font(.system(size: 20))
                    .lineSpacing(3)
                    .foregroundStyle(ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .id(instruction)
                    .transition(.opacity)
            }
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .topLeading)
            .padding(.top, 4)
            .animation(.easeInOut(duration: 0.4), value: instruction)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(track)
                    Capsule().fill(accent)
                        .frame(width: geo.size.width * CGFloat(elapsed / totalSeconds))
                }
            }
            .frame(height: 6)
            .padding(.top, 14)

            // Elapsed / remaining
            HStack {
                Text(elapsedLabel)
                Spacer()
                Text(remainingLabel)
            }
            .font(.system(size: 14))
            .monospacedDigit()
            .foregroundStyle(caption)
            .padding(.top, 10)

            // Appears once the timer is over
            if isComplete {
                Button(action: onContinue) {
                    Text(screen?.sessionContinueButton ?? "")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(accent, in: Capsule())
                }
                .padding(.top, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        )
        .animation(.spring(duration: 0.4), value: isComplete)
    }

    private var elapsedLabel: String {
        guard let screen else { return "" }
        return screen.format(screen.sessionElapsedFormat, [
            "duration": format(Int(elapsed))
        ])
    }

    private var remainingLabel: String {
        guard let screen else { return "" }
        return screen.format(screen.sessionRemainingFormat, [
            "duration": format(Int(totalSeconds) - Int(elapsed))
        ])
    }

    // MARK: Subtle reset + play/pause

    private var controls: some View {
        HStack(spacing: 8) {
            controlButton(icon: screen?.sessionRestartIcon ?? "",
                          label: screen?.sessionRestartLabel ?? "") {
                elapsed = 0
                lastTick = Date()
                isRunning = true
            }
            controlButton(icon: isRunning ? (screen?.sessionPauseIcon ?? "") : (screen?.sessionPlayIcon ?? ""),
                          label: isRunning ? (screen?.sessionPauseLabel ?? "") : (screen?.sessionPlayLabel ?? "")) {
                lastTick = Date()
                isRunning.toggle()
            }
        }
    }

    private func controlButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(caption)
                .frame(width: 32, height: 32)
                .background(Circle().fill(track))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

#Preview {
    GuideSessionView(guide: .preview)
        .environment(ImageryGuideStore())
}
