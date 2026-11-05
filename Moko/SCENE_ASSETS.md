# Scene assets and contrast

Category scenes are stored as 800×450 WebP payloads in `.dataset` asset catalog entries, loaded by `NSDataAsset`, and decoded to `CGImage` off the main thread. Each scene is 22% opacity and right aligned under a horizontal fade. Light and dimmed/cool dark variants are selected from the active color scheme. Each file is below 120 KB.

| Category | Light asset | Light size | Dark asset | Dark size |
|---|---|---:|---|---:|
| Work | `QuestSceneWorkLight` | 16.3 KB | `QuestSceneWorkDark` | 11.1 KB |
| Friends | `QuestSceneFriendsLight` | 25.9 KB | `QuestSceneFriendsDark` | 17.1 KB |
| Family | `QuestSceneFamilyLight` | 17.9 KB | `QuestSceneFamilyDark` | 11.9 KB |
| Date | `QuestSceneDateLight` | 28.0 KB | `QuestSceneDateDark` | 17.7 KB |
| Interview | `QuestSceneInterviewLight` | 22.5 KB | `QuestSceneInterviewDark` | 14.9 KB |
| Events | `QuestSceneEventsLight` | 22.1 KB | `QuestSceneEventsDark` | 14.4 KB |
| Calm | `QuestSceneCalmLight` | 11.0 KB | `QuestSceneCalmDark` | 7.1 KB |
| Explore | `QuestSceneExploreLight` | 19.9 KB | `QuestSceneExploreDark` | 12.8 KB |

## Contrast

Scene visibility is removed behind copy by an opaque tinted-card wash through 65% of card width, then eased to 94% opacity at 90%; the scene itself reaches only 22% opacity. This keeps scene pixels from reducing text contrast in the text region. WCAG contrast ratios for the light/dark scene underlay with the card tint (text foregrounds used by the cards: `#1B422F`, `#5C4330`, and `#6F6762`) are governed by the card fill. Ratios for the three tints (`#F6EBD3`, `#E2F1DC`, `#DCEEF0`) are respectively 9.50/7.71/4.68, 9.56/7.76/4.71, and 9.39/7.62/4.62; the lowest is 4.62:1. Scene category mapping is in `Moko/Moko/UIScreens/shared/AppBackground.swift`.
