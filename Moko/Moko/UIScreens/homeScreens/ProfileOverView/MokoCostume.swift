import SwiftUI
import UIKit

struct MokoCostume: Identifiable, Hashable {
    let level: Int
    let name: String
    let assetName: String
    var id: Int { level }

    static let all: [MokoCostume] = [
        .init(level: 1, name: "Everyday Starter", assetName: "MokoCostume01"),
        .init(level: 2, name: "Cozy Cardigan", assetName: "MokoCostume02"),
        .init(level: 3, name: "Canteen Casual", assetName: "MokoCostume03"),
        .init(level: 4, name: "Garden Helper", assetName: "MokoCostume04"),
        .init(level: 5, name: "Campus Classic", assetName: "MokoCostume05"),
        .init(level: 6, name: "Thoughtful Scholar", assetName: "MokoCostume06"),
        .init(level: 8, name: "Confident Blazer", assetName: "MokoCostume07"),
        .init(level: 10, name: "Weekend Explorer", assetName: "MokoCostume08"),
        .init(level: 12, name: "Modern Kurta", assetName: "MokoCostume09"),
        .init(level: 14, name: "Studio Artist", assetName: "MokoCostume10"),
        .init(level: 16, name: "Mountain Guide", assetName: "MokoCostume11"),
        .init(level: 18, name: "Celebration Suit", assetName: "MokoCostume12"),
        .init(level: 20, name: "Heritage Waistcoat", assetName: "MokoCostume13"),
        .init(level: 24, name: "Mentor Look", assetName: "MokoCostume14"),
        .init(level: 30, name: "Level Master", assetName: "MokoCostume15")
    ]

    static func unlockedCount(for level: Int) -> Int {
        all.filter { $0.level <= level }.count
    }

    static func selected(unlockedAt level: Int, selection: Int) -> MokoCostume {
        all.first(where: { $0.level == selection && $0.level <= level })
            ?? all.last(where: { $0.level <= level })!
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
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(costume.assetName)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.035)
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
                        .font(.headline)
                        .foregroundStyle(ProfilePalette.text)
                    Text("Level \(level) · \(MokoCostume.unlockedCount(for: level)) of \(MokoCostume.all.count) unlocked")
                        .font(.subheadline)
                        .foregroundStyle(ProfilePalette.secondary)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .padding(.vertical, 12)
            }

            Section {
                ForEach(MokoCostume.all) { costume in
                    let unlocked = level >= costume.level
                    Button {
                        guard unlocked else { return }
                        selectedLevel = costume.level
                    } label: {
                        HStack(spacing: 14) {
                            Image(costume.assetName)
                                .resizable()
                                .scaledToFit()
                                .padding(3)
                                .frame(width: 64, height: 64)
                                .background(ProfilePalette.lime.opacity(unlocked ? 0.7 : 0.35), in: Circle())
                                .overlay(Circle().stroke(ProfilePalette.accent.opacity(0.15), lineWidth: 1))
                                .opacity(unlocked ? 1 : 0.55)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(costume.name)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(ProfilePalette.text)
                                Text(unlocked ? "Unlocked · Level \(costume.level)" : "Unlocks at Level \(costume.level)")
                                    .font(.subheadline)
                                    .foregroundStyle(ProfilePalette.secondary)
                            }
                            Spacer(minLength: 8)
                            if selectedLevel == costume.level && unlocked {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(ProfilePalette.success)
                                    .accessibilityLabel("Selected")
                            } else if !unlocked {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(ProfilePalette.secondary)
                                    .accessibilityLabel("Locked")
                            }
                        }
                        .frame(minHeight: 68)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!unlocked)
                }
            } header: {
                Text("Costumes · \(MokoCostume.all.count)")
            } footer: {
                Text("Keep practicing to unlock each new look. Costumes are never for sale.")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(ProfilePalette.background)
        .navigationTitle("Moko’s wardrobe")
        .navigationBarTitleDisplayMode(.large)
        .tint(ProfilePalette.accent)
    }
}
