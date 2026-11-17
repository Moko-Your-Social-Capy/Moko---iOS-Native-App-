//
//  SettingsInfoScreens.swift
//  Moko
//
//  Real destinations for the Settings rows: privacy overview, privacy policy,
//  terms of service, help & support, and about Moko.
//
//  The small private views at the top (InfoScrollView, InfoCard, ...) are the
//  building blocks every screen in this file shares, so they all look the same.
//

import SwiftUI

// MARK: - Shared style

/// The colours used by every screen in this file.
private enum InfoTheme {
    static let screenBg = ProfilePalette.background
    static let deepGreen = ProfilePalette.accent
    static let cream = ProfilePalette.grouped
    static let ink = ProfilePalette.text
}

/// A scrolling page with the standard padding and background.
/// `@ViewBuilder` lets you pass several views inside `{ }`, like a VStack.
private struct InfoScrollView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(MokoBackdrop())
    }
}

/// A rounded cream card that groups related content.
private struct InfoCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .mokoCard(fill: InfoTheme.cream)
    }
}

/// A heading with a paragraph under it.
private struct InfoSection: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(InfoTheme.ink)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(InfoTheme.ink.opacity(0.72))
                // Lets long text wrap onto more lines instead of being cut off with "...".
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// An icon on the left, with a title and paragraph on the right.
private struct InfoPoint: View {
    let symbol: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(InfoTheme.deepGreen)
                .frame(width: 34, height: 34)
                .background(Circle().fill(InfoTheme.cream))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(InfoTheme.ink)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(InfoTheme.ink.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// The label for a NavigationLink row: icon, title and a ">" arrow.
private struct InfoLinkRow: View {
    let title: String
    let symbol: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(InfoTheme.deepGreen)
                .frame(width: 32, height: 32)
                .background(Circle().fill(InfoTheme.cream))

            Text(title)
                .foregroundStyle(InfoTheme.ink)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        // Makes the empty space in the row tappable too, not just the text.
        .contentShape(Rectangle())
    }
}

/// A question that opens to show its answer. DisclosureGroup handles the open/close arrow.
private struct FAQItem: View {
    let question: String
    let answer: String

    var body: some View {
        DisclosureGroup {
            Text(answer)
                .font(.subheadline)
                .foregroundStyle(InfoTheme.ink.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 6)
        } label: {
            Text(question)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(InfoTheme.ink)
        }
        .tint(InfoTheme.deepGreen)
    }
}

// `mailto:` links open the Mail app with this address filled in.
private let supportEmailURL = URL(string: "mailto:support@moko.app")
private let supportEmail = "support@moko.app"

// MARK: - Privacy overview

/// Settings → "Data we collect": a short, plain summary.
struct ProfileOverViewPrivacy: View {
    var body: some View {
        InfoScrollView {
            Text("Your account details support sign-in. Your practice history is stored on this device.")
                .font(.subheadline)
                .foregroundStyle(InfoTheme.ink.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)

            InfoCard {
                InfoPoint(
                    symbol: "iphone",
                    title: "Profile and practice data",
                    text: "Your profile, self-rated scores, reflection text, quests, XP, streaks and calm-session history are stored locally on this device."
                )
                Divider()
                InfoPoint(
                    symbol: "person.badge.key",
                    title: "Account information",
                    text: "Your email address and authentication session are handled by Supabase. Moko does not store your password."
                )
                Divider()
                InfoPoint(
                    symbol: "hand.raised",
                    title: "Permissions you choose",
                    text: "The microphone is used only for a voice reflection, the camera only for the Mirror Reflection preview, and notifications only for the daily reminder. Moko asks when you turn one on and shows each status in Settings. Text reflections need no permission."
                )
            }

            VStack(spacing: 0) {
                NavigationLink {
                    ProfileOverViewPrivacyPolicy()
                } label: {
                    InfoLinkRow(title: "Privacy Policy", symbol: "shield")
                }

                Divider().padding(.leading, 48)

                NavigationLink {
                    ProfileOverViewAccountAndData()
                } label: {
                    InfoLinkRow(title: "Account & Data", symbol: "person.crop.circle")
                }

                Divider().padding(.leading, 48)

                NavigationLink {
                    ProfileOverViewNotifications()
                } label: {
                    InfoLinkRow(title: "Reminders & Notifications", symbol: "bell")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(InfoTheme.cream, in: RoundedRectangle(cornerRadius: 20))
            .tint(InfoTheme.deepGreen)
        }
        .navigationTitle("Data we collect")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Privacy Policy

/// The full privacy policy text.
struct ProfileOverViewPrivacyPolicy: View {
    var body: some View {
        InfoScrollView {
            Text("Last updated 1 November 2026")
                .font(.footnote)
                .foregroundStyle(InfoTheme.ink.opacity(0.72))

            InfoCard {
                InfoSection(
                    title: "Overview",
                    text: "This policy explains how Moko handles information when you use the app. Moko is a personal wellbeing and habit-building app. We keep the collection of personal information to what is needed to provide the service."
                )
            }

            InfoCard {
                InfoSection(
                    title: "Information we collect",
                    text: "Account details: your email address and authentication session are handled by Supabase when you create an account or sign in. Moko does not store your password.\n\nApp content: your profile name, optional username, age range, photo, onboarding answers, quest notes, self-rated scores, reflection text, XP, streaks and calm-session history are stored locally on this device. In this build, this content is not uploaded to Moko’s server.\n\nVoice: if you choose a voice reflection, the microphone records audio and Apple’s speech recognition turns it into text for that debrief. You can type instead, and you can turn microphone access off in Settings."
                )
            }

            InfoCard {
                InfoSection(
                    title: "How we use information",
                    text: "We use your account details to authenticate you and keep your session secure. Information stored on your device is used only to show your profile, progress, streaks, Insights and history inside Moko."
                )
            }

            InfoCard {
                InfoSection(
                    title: "Storage and retention",
                    text: "Local app content stays on this device until you delete your account in Moko or remove the app. Signing out does not erase local history. Supabase keeps account credentials until account deletion succeeds."
                )
            }

            InfoCard {
                InfoSection(
                    title: "Who can see your data",
                    text: "Your local reflections and scores are available to people with access to your unlocked device. Supabase processes account sign-in details. Moko does not sell your data or use it for targeted advertising."
                )
            }

            InfoCard {
                InfoSection(
                    title: "Your choices",
                    text: "Export your local data or delete your account from Account & Data. Manage existing permissions through Settings → Manage Permissions. Text reflections do not require microphone access."
                )
            }

            InfoCard {
                InfoSection(
                    title: "Children",
                    text: "Moko is intended for people aged 13 and over. We do not knowingly collect personal information from children under 13."
                )
            }

            InfoCard {
                InfoSection(
                    title: "Wellbeing",
                    text: "Moko is a self-improvement tool. It is not medical advice or a substitute for professional care."
                )
            }

            InfoCard {
                InfoSection(
                    title: "Need support?",
                    text: "If you are in India and need mental health support, call Tele-MANAS at 14416 or 1800-89-14416."
                )
            }

            InfoCard {
                InfoSection(
                    title: "Contact",
                    text: "Questions about this policy or your data? Email us at \(supportEmail)."
                )

                if let supportEmailURL {
                    Link(destination: supportEmailURL) {
                        Label("Email support", systemImage: "envelope")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(InfoTheme.deepGreen)
                }
            }
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Terms of Service

struct ProfileOverViewTerms: View {
    var body: some View {
        InfoScrollView {
            Text("Last updated 1 November 2026")
                .font(.footnote)
                .foregroundStyle(InfoTheme.ink.opacity(0.72))

            InfoCard {
                InfoSection(
                    title: "Using Moko",
                    text: "By using Moko, you agree to these terms. Moko is a self-improvement and wellbeing app that offers daily quests, reflections and calming exercises. You may use the app for personal, non-commercial purposes."
                )
            }

            InfoCard {
                InfoSection(
                    title: "Your account",
                    text: "You are responsible for keeping your sign-in details secure and for activity that happens through your account. Provide accurate information and tell us if you believe your account has been used without permission."
                )
            }

            InfoCard {
                InfoSection(
                    title: "Your content",
                    text: "You keep ownership of the reflections, notes and other content you create in Moko. Your content stays on your device unless you choose to share it. You are responsible for what you write and share."
                )
            }

            InfoCard {
                InfoSection(
                    title: "Wellbeing disclaimer",
                    text: "Moko supports healthy habits but is not a medical device and does not provide diagnosis, treatment or emergency support. If you are in crisis or need urgent help, contact your local emergency services or a qualified professional."
                )
            }

            InfoCard {
                InfoSection(
                    title: "Availability and changes",
                    text: "We may update, improve or occasionally interrupt the app. We may also update these terms when the service changes. Continued use after an update means you accept the revised terms."
                )
            }

            InfoCard {
                InfoSection(
                    title: "Ending use",
                    text: "You can stop using Moko at any time and delete your account from Account & Data. We may suspend access if the app is used in a way that harms Moko, another person or the service."
                )
            }

            InfoCard {
                InfoSection(
                    title: "Contact",
                    text: "Questions about these terms? Email us at \(supportEmail)."
                )

                // `if let` only shows the link if the email URL was valid.
                if let supportEmailURL {
                    Link(destination: supportEmailURL) {
                        Label("Email support", systemImage: "envelope")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(InfoTheme.deepGreen)
                }
            }
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Help & Support

/// FAQs and a button to email support.
struct ProfileOverViewHelpSupport: View {
    var body: some View {
        InfoScrollView {
            InfoCard {
                InfoPoint(
                    symbol: "questionmark.bubble",
                    title: "We’re here to help",
                    text: "Find quick answers below, or send us an email if something still isn’t working."
                )
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Common questions")
                    .font(.title3.bold())
                    .padding(.horizontal, 4)

                InfoCard {
                    FAQItem(
                        question: "How do I complete a quest?",
                        answer: "Open Today’s mission on the Overview tab, then slide to complete it. Finished quests appear in the Quests tab, where you can start a debrief."
                    )
                    Divider()
                    FAQItem(
                        question: "What happens if I leave a debrief?",
                        answer: "Your progress is saved. Choose Finish later and Moko will keep the debrief ready for you on the Overview tab."
                    )
                    Divider()
                    FAQItem(
                        question: "Why aren’t reminders appearing?",
                        answer: "Check Settings → Notifications. If Moko is not allowed to send notifications, open iOS Settings and turn them on, then enable the daily reminder again."
                    )
                    Divider()
                    FAQItem(
                        question: "How do I export or delete my data?",
                        answer: "Go to Settings → Account & Data. Export my data opens the share sheet. Delete account removes your profile and history from this device and signs you out."
                    )
                    Divider()
                    FAQItem(
                        question: "Will signing out erase my progress?",
                        answer: "No. Signing out keeps your local profile, quests and history on this device. Delete account is the option that removes your data."
                    )
                }
            }

            InfoCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Still need a hand?")
                        .font(.headline)
                    Text("Tell us what happened and which screen you were on. We usually reply within two working days.")
                        .font(.subheadline)
                        .foregroundStyle(InfoTheme.ink.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let supportEmailURL {
                    Link(destination: supportEmailURL) {
                        Label("Email support", systemImage: "envelope")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(InfoTheme.deepGreen)
                }
            }

            VStack(spacing: 0) {
                NavigationLink {
                    ProfileOverViewPrivacyPolicy()
                } label: {
                    InfoLinkRow(title: "Privacy Policy", symbol: "shield")
                }

                Divider().padding(.leading, 48)

                NavigationLink {
                    ProfileOverViewTerms()
                } label: {
                    InfoLinkRow(title: "Terms of Service", symbol: "doc")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(InfoTheme.cream, in: RoundedRectangle(cornerRadius: 20))
            .tint(InfoTheme.deepGreen)
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - About Moko

/// App name, version number and what Moko is for.
struct ProfileOverViewAboutMoko: View {
    // Reads the version and build numbers from the app's Info.plist (set in Xcode → General).
    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        InfoScrollView {
            VStack(spacing: 10) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(InfoTheme.deepGreen)
                    .frame(width: 82, height: 82)
                    .background(Circle().fill(InfoTheme.cream))

                Text("Moko")
                    .font(.largeTitle.bold())

                Text("Small daily nudges, an honest chat after.")
                    .font(.subheadline)
                    .foregroundStyle(InfoTheme.ink.opacity(0.72))
                    .multilineTextAlignment(.center)

                Text(versionText)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)

            InfoCard {
                InfoSection(
                    title: "Why Moko exists",
                    text: "Building a habit is easier when it feels small. Moko gives you one gentle mission at a time, a space to reflect afterwards, and simple calming exercises for the moments in between."
                )
            }

            InfoCard {
                InfoPoint(
                    symbol: "checkmark.seal",
                    title: "Designed to stay out of the way",
                    text: "No feeds to scroll, no streak guilt and no advertising. Just a short daily practice you can return to."
                )
                Divider()
                InfoPoint(
                    symbol: "lock.shield",
                    title: "Personal by design",
                    text: "Your reflections and progress stay on your device. You choose when to export or delete them."
                )
                Divider()
                InfoPoint(
                    symbol: "heart",
                    title: "Made with care",
                    text: "Moko is built with SwiftUI and SwiftData, with account authentication provided by Supabase."
                )
            }

            VStack(spacing: 0) {
                NavigationLink {
                    ProfileOverViewPrivacyPolicy()
                } label: {
                    InfoLinkRow(title: "Privacy Policy", symbol: "shield")
                }

                Divider().padding(.leading, 48)

                NavigationLink {
                    ProfileOverViewTerms()
                } label: {
                    InfoLinkRow(title: "Terms of Service", symbol: "doc")
                }

                Divider().padding(.leading, 48)

                NavigationLink {
                    ProfileOverViewHelpSupport()
                } label: {
                    InfoLinkRow(title: "Help & Support", symbol: "questionmark.circle")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(InfoTheme.cream, in: RoundedRectangle(cornerRadius: 20))
            .tint(InfoTheme.deepGreen)

            Text("© 2026 Moko. Made with care.")
                .font(.caption)
                .foregroundStyle(InfoTheme.ink.opacity(0.72))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .navigationTitle("About Moko")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview("Privacy") {
    NavigationStack { ProfileOverViewPrivacy() }
}

#Preview("Privacy Policy") {
    NavigationStack { ProfileOverViewPrivacyPolicy() }
}

#Preview("Terms") {
    NavigationStack { ProfileOverViewTerms() }
}

#Preview("Help") {
    NavigationStack { ProfileOverViewHelpSupport() }
}

#Preview("About") {
    NavigationStack { ProfileOverViewAboutMoko() }
}
