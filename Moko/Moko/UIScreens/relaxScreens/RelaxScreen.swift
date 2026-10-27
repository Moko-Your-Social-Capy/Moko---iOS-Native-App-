//
//  RelaxScreen.swift
//  Moko
//
//  Relax tab integrating the new Imagery Guide relax flow.
//

import SwiftUI

enum RelaxSession: String, CaseIterable, Identifiable {
    case boxBreathing
    case grounding
    case imagery
    case mirror

    var id: String { rawValue }

    var title: String {
        switch self {
        case .boxBreathing: return "Box Breathing"
        case .grounding:    return "Grounding"
        case .imagery:      return "Imagery"
        case .mirror:       return "Mirror"
        }
    }
}

struct BreathingDotsIcon: View {
    var color: Color = Color(red: 54/255, green: 89/255, blue: 72/255)
    var body: some View {
        Circle()
            .fill(color.opacity(0.15))
            .overlay(
                Circle()
                    .stroke(color, lineWidth: 3)
                    .scaleEffect(0.7)
            )
    }
}

struct RelaxSessionIcon: View {
    let session: RelaxSession
    var color: Color = Color(red: 54/255, green: 89/255, blue: 72/255)

    var body: some View {
        Image(systemName: "sparkles")
            .font(.system(size: 24))
            .foregroundColor(color)
    }
}

struct RelaxScreen: View {
    @Binding var selectedTab: MokoTab

    init(selectedTab: Binding<MokoTab> = .constant(.relax), onStartBreathing: ((Int) -> Void)? = nil, onStartSession: ((RelaxSession) -> Void)? = nil) {
        self._selectedTab = selectedTab
    }

    var body: some View {
        RelaxFlow()
    }
}

#Preview {
    RelaxScreen(selectedTab: .constant(.relax))
}
