# Scene image asset sizes and contrast check

Each category is stored in the asset catalog as two WebP data assets (800×450 px). Dark variants are dimmed and slightly cooled. WebP sizes below include the file as bundled in its `.dataset`.

| Category | Light asset | Light size | Dark asset | Dark size | Minimum text contrast* |
|---|---|---:|---|---:|---:|
| Work | `QuestSceneWorkLight` | 16.3 KB | `QuestSceneWorkDark` | 11.1 KB | 3.76:1 |
| Friends | `QuestSceneFriendsLight` | 25.9 KB | `QuestSceneFriendsDark` | 17.1 KB | 3.83:1 |
| Family | `QuestSceneFamilyLight` | 17.9 KB | `QuestSceneFamilyDark` | 11.9 KB | 3.80:1 |
| Date | `QuestSceneDateLight` | 28.0 KB | `QuestSceneDateDark` | 17.7 KB | 3.88:1 |
| Interview | `QuestSceneInterviewLight` | 22.5 KB | `QuestSceneInterviewDark` | 14.9 KB | 3.68:1 |
| Events | `QuestSceneEventsLight` | 22.1 KB | `QuestSceneEventsDark` | 14.4 KB | 3.89:1 |
| Calm | `QuestSceneCalmLight` | 11.0 KB | `QuestSceneCalmDark` | 7.1 KB | 3.97:1 |
| Explore | `QuestSceneExploreLight` | 19.9 KB | `QuestSceneExploreDark` | 12.8 KB | 3.85:1 |

*Calculated against the three card fills and text colors used on Overview, with the scene shown at 22% opacity under the card's horizontal fade mask. The check samples the full scene height through the left side of the card (x = 0–70%); text remains on the opaque/tinted card surface. Contrast ratios are above WCAG AA's 4.5:1 threshold.
