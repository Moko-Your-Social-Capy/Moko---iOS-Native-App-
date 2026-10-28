//
//  GuideSessionView.swift
//  imageryGuide
//
//  Created by user@77 on 26/10/26.
//

import SwiftUI
import Combine

struct GuideSessionView: View {
    let guide: ImageryGuide
    var totalSeconds: TimeInterval = 120          // 2 minutes
    var onContinue: () -> Void = {}

    @State private var elapsed: TimeInterval = 0
    @State private var isRunning = true           // starts as soon as the screen opens
    @State private var lastTick = Date()

    private let ticker = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    private let accent   = Color(hex: 0x365948)
    private let tileFill = Color(hex: 0xE6EFE9)
    private let ink      = Color(hex: 0x2F2A28)
    private let caption  = Color(hex: 0x6F6762)
    private let track    = Color(hex: 0xEDEDED)

    // MARK: Derived state

    private var steps: [String] { guide.sessionSteps }
    private var isComplete: Bool { elapsed >= totalSeconds }

    private var stepIndex: Int {
        let perStep = totalSeconds / Double(steps.count)
        return min(Int(elapsed / perStep), steps.count - 1)
    }

    private var headerText: String {
        if isComplete { return "SESSION COMPLETE" }
        return "STEP \(stepIndex + 1) OF \(steps.count)" + (isRunning ? "" : " · PAUSED")
    }

    private var instruction: String {
        isComplete
        ? "You imagined for \(format(Int(totalSeconds))). Take a moment before you continue."
        : steps[stepIndex]
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
        .onReceive(ticker) { date in
            let dt = min(date.timeIntervalSince(lastTick), 0.5)
            lastTick = date
            guard isRunning, !isComplete else { return }
            elapsed = min(totalSeconds, elapsed + dt)
            if elapsed >= totalSeconds { isRunning = false }
        }
        .onDisappear { isRunning = false }
        .sensoryFeedback(.impact(weight: .light), trigger: stepIndex)
        .sensoryFeedback(.success, trigger: isComplete)
    }

    // MARK: Background photo

    private var background: some View {
        Group {
            if let name = guide.sessionImage {
                Color.clear
                    .overlay {
                        Image(name)
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(guide.sessionImageScale, anchor: .top)
                            .offset(x: guide.sessionImageShift)   // framing used in the design
                    }
                    .clipped()
            } else {
                // Guides without a photo yet
                ZStack {
                    tileFill
                    Image(systemName: guide.icon)
                        .font(.system(size: 140, weight: .semibold))
                        .foregroundStyle(accent.opacity(0.35))
                }
            }
        }
        .ignoresSafeArea()
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
                Text("Elapsed \(format(Int(elapsed)))")
                Spacer()
                Text("Remaining \(format(Int(totalSeconds) - Int(elapsed)))")
            }
            .font(.system(size: 14))
            .monospacedDigit()
            .foregroundStyle(caption)
            .padding(.top, 10)

            // Appears once the 2 minutes are over
            if isComplete {
                Button(action: onContinue) {
                    Text("Continue")
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

    // MARK: Subtle reset + play/pause

    private var controls: some View {
        HStack(spacing: 8) {
            controlButton(icon: "arrow.counterclockwise", label: "Restart") {
                elapsed = 0
                lastTick = Date()
                isRunning = true
            }
            controlButton(icon: isRunning ? "pause.fill" : "play.fill",
                          label: isRunning ? "Pause" : "Play") {
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
    GuideSessionView(guide: ImageryGuide.all[0])
}
