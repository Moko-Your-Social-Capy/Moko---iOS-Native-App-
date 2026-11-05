import SwiftUI
import UIKit

enum MokoCostumeTheme: String, CaseIterable, Identifiable {
    case racing = "Racing"
    case storm = "Storm Heroes"
    case cricket = "Cricket"
    var id: String { rawValue }
}

struct MokoCostume: Identifiable, Hashable {
    let id: Int
    let theme: MokoCostumeTheme
    let level: Int
    let name: String
    let assetName: String

    static let all: [MokoCostume] = [
        .init(id: 1, theme: .racing, level: 1, name: "Crimson Apex #1", assetName: "racing_01"),
        .init(id: 2, theme: .racing, level: 2, name: "Ocean Velocity #7", assetName: "racing_07"),
        .init(id: 3, theme: .racing, level: 3, name: "Sunset Circuit #11", assetName: "racing_11"),
        .init(id: 4, theme: .racing, level: 4, name: "Pine Sprint #27", assetName: "racing_27"),
        .init(id: 5, theme: .storm, level: 5, name: "Silver Surge", assetName: "storm_01"),
        .init(id: 6, theme: .storm, level: 6, name: "Cloud Guardian", assetName: "storm_02"),
        .init(id: 7, theme: .storm, level: 7, name: "Thunder Scout", assetName: "storm_03"),
        .init(id: 8, theme: .storm, level: 8, name: "Sky Sentinel", assetName: "storm_04"),
        .init(id: 9, theme: .cricket, level: 9, name: "Club Batter", assetName: "cricket_01"),
        .init(id: 10, theme: .cricket, level: 10, name: "Cap and Kit", assetName: "cricket_02"),
        .init(id: 11, theme: .cricket, level: 11, name: "Helmet Ready", assetName: "cricket_03"),
        .init(id: 12, theme: .cricket, level: 12, name: "Cup Winner", assetName: "cricket_04")
    ]

    static func unlockedCount(for level: Int) -> Int {
        all.filter { $0.level <= level }.count
    }

    static func selected(unlockedAt level: Int, selection: Int) -> MokoCostume {
        all.first(where: { $0.level == selection && $0.level <= level })
            ?? all.last(where: { $0.level <= level })
            ?? all[0]
    }
}

struct MokoCostumeAvatar: View {
    let level: Int
    let photoData: Data?
    var size: CGFloat
    @AppStorage("moko.selectedCostumeLevel") private var selectedLevel = 1

    private var costume: MokoCostume { .selected(unlockedAt: level, selection: selectedLevel) }

    var body: some View {
        Group {
            if let photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(costume.assetName).resizable().scaledToFit().padding(size * 0.035)
            }
        }
        .frame(width: size, height: size)
        .background(ProfilePalette.grouped, in: Circle())
        .clipShape(Circle())
        .overlay(Circle().stroke(ProfilePalette.accent.opacity(0.18), lineWidth: 1))
        .accessibilityLabel(photoData == nil ? "Moko wearing \(costume.name)" : "Profile photo")
    }
}

struct MokoWardrobeView: View {
    let level: Int
    @AppStorage("moko.selectedCostumeLevel") private var selectedLevel = 1

    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    MokoCostumeAvatar(level: level, photoData: nil, size: 144)
                    Text(MokoCostume.selected(unlockedAt: level, selection: selectedLevel).name)
                        .font(.headline).foregroundStyle(ProfilePalette.text)
                    Text("Level \(level) · \(MokoCostume.unlockedCount(for: level)) of 12 unlocked")
                        .font(.subheadline).foregroundStyle(ProfilePalette.secondary)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .padding(.vertical, 12)
            }

            ForEach(MokoCostumeTheme.allCases) { theme in
                Section {
                    ForEach(MokoCostume.all.filter { $0.theme == theme }) { costume in
                        costumeRow(costume)
                    }
                } header: {
                    Text(theme.rawValue)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(ProfilePalette.background)
        .navigationTitle("Moko’s wardrobe")
        .navigationBarTitleDisplayMode(.large)
        .tint(ProfilePalette.accent)
    }

    private func costumeRow(_ costume: MokoCostume) -> some View {
        let unlocked = level >= costume.level
        return Button {
            guard unlocked else { return }
            selectedLevel = costume.level
        } label: {
            HStack(spacing: 14) {
                Image(costume.assetName)
                    .resizable().scaledToFit().padding(3)
                    .frame(width: 72, height: 72)
                    .background(ProfilePalette.lightGreen.opacity(unlocked ? 0.7 : 0.4), in: Circle())
                    .saturation(unlocked ? 1 : 0)
                    .opacity(unlocked ? 1 : 0.48)
                VStack(alignment: .leading, spacing: 4) {
                    Text(costume.name).font(.body.weight(.semibold)).foregroundStyle(ProfilePalette.text)
                    Text(unlocked ? "Unlocked · Level \(costume.level)" : "Unlocks at Level \(costume.level) · \((costume.level - 1) * 400) XP")
                        .font(.subheadline).foregroundStyle(ProfilePalette.secondary)
                }
                Spacer(minLength: 8)
                if selectedLevel == costume.level && unlocked {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(ProfilePalette.accent)
                        .accessibilityLabel("Equipped")
                } else if !unlocked {
                    Image(systemName: "lock.fill").foregroundStyle(ProfilePalette.secondary)
                        .accessibilityLabel("Locked")
                }
            }
            .frame(minHeight: 76)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
    }
}
