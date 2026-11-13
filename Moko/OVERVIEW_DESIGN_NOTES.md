# Overview & Debrief — Design Compliance Notes

Audit of the implemented screens against **"Moco Screen Theme" v1.0** (§1 scale → §8 acceptance).
Scope: `Overview.swift`, `OverviewDebriefDone.swift`, `OverviewResumeScreen.swift`, `Questdebrief.swift`.
Originally read-only. No source file was modified to produce this.

> **Status — `Overview.swift` has since been migrated.**
> The theme now lives in code as `MocoScreenTheme` (`Features/DesignSystem/MocoScreenTheme.swift`),
> with the shared shells in `MocoComponents.swift` (card, backdrop, slide control, radar, bars).
> Everything in §2 below that concerns the *done* state is now implemented; the deltas listed there
> are kept as the record of what was wrong before the migration. §3 (resumed) and §4 (debrief)
> still describe the current code — those two screens have not been migrated yet.

Naming follows the prompt's own law (§0): each value is stated **once**, in §0, then referred to by
token name. Where code deviates, the code's literal is shown once in the delta table.

---

## 0 · Registry (values stated once)

Only the tokens and code literals this audit needs.

| Token | Value |
|---|---|
| `moco.color.canvas.top` | #F3F8F0 |
| `moco.color.canvas.bottom` | #E7F0E2 |
| `moco.color.surface.white` | #FFFFFF |
| `moco.color.surface.lavender` | #EDEFF8 |
| `moco.color.stroke.ink` | #17161C |
| `moco.color.text.title` | #17161C |
| `moco.color.text.body` | #5E5B6A |
| `moco.color.text.muted` | #6E6B7A |
| `moco.color.state.emptyTitle` | #2E5B4D |
| `moco.color.data.numeral` | #55457F |
| `moco.color.data.violet` | #8C7CB8 |
| `moco.color.data.violet.deep` | #55457F |
| `moco.color.data.grid` | #C9CEDD |
| `moco.color.data.node` | #2B2440 |
| `moco.color.accent.blue` | #2168E0 |
| `moco.color.countdown.value` | #47679B |
| `moco.color.avatar.fill` | #C9CFE6 |
| `moco.space.page` | 24 |
| `moco.space.card` | 18 / 20 |
| `moco.space.gap` | 16 / 8 |
| `moco.radius.card` | 22 |
| `moco.radius.inner` | 14 |
| `moco.radius.knob` | 23 |
| `moco.stroke.card` | 2 |
| `moco.stroke.data` | 1.5 |
| `moco.type.title1` | 32 / 38 Bold |
| `moco.type.title2` | 22 / 28 Semibold |
| `moco.type.section` | 19 / 24 Semibold |
| `moco.type.cardTitle` | 17 / 22 Semibold |
| `moco.type.body` | 15 / 22 Regular |
| `moco.type.caption` | 13 / 18 Medium |
| `moco.type.numeral` | 44 / 44 Bold |
| `moco.type.unit` | 15 / 20 Medium |
| `moco.type.slider` | 15 / 20 Semibold |

**Code-side literals referenced below** (each appears once):

| Code symbol | Literal | Where |
|---|---|---|
| `MokoTheme.limeBackground` | #F6FAE8 (flat fill) | `Overview.swift:68`, `OverviewResumeScreen.swift:42`, `Questdebrief.swift:28` |
| `primaryGreen` | #1B422F | `Overview.swift:69`, `OverviewResumeScreen.swift:43` |
| `micGreen` | #2F4F40 | `Overview.swift:70`, `OverviewResumeScreen.swift:44` |
| `MokoTheme.titleBrown` | #5C4330 | `Overview.swift:71`, `OverviewResumeScreen.swift:45`, `Questdebrief.swift:31` |
| `subtextGray` | #6F6762 | `Overview.swift:72`, `OverviewResumeScreen.swift:46`, `Questdebrief.swift:32` |
| `DebriefStyle.green` | #365948 | `Questdebrief.swift:29` |
| `DebriefStyle.cream` | #FBF7EE | `Questdebrief.swift:33` |
| `DebriefStyle.border` | #EAE0CC | `Questdebrief.swift:34` |
| `DebriefStyle.sand` | #E9E2D6 | `Questdebrief.swift:35` |
| `DebriefStyle.rust` | #B04E3A | `Questdebrief.swift:36` |
| `DebriefStyle.mint` | #CBE6D3 | `Questdebrief.swift:37` |

---

## 1 · Verdict summary

`✓` conforms · `~` close, wrong token/geometry · `✗` absent or contradicted

| §8 Acceptance item | Overview `.todo` | Overview `.debriefDone` | Overview `.resume` | Debrief |
|---|---|---|---|---|
| 1 · Every card has a `moco.stroke.card` outline of `stroke.ink` | ✗ | ✗ | ✗ | ✗ |
| 2 · Green canvas + leafy bush/leaf vectors at 15–18% | ✗ | ✗ | ✗ | ✗ |
| 3 · Type follows `moco.type.*`; nothing below 13 pt except tab | ✗ | ✗ | ✗ | ✗ |
| 4 · Slide implements 5 states + 4 a11y rules | ✗ | n/a | ✗ | ✗ |
| 5 · Blue only on `Control/Slide` + completion flash | ✗ | ✓ (no blue at all) | ✗ | ✓ |
| 6 · Green type only on `state.emptyTitle` | ✗ | ✗ | ✗ | ✗ |
| 7 · No glass / blur / neon / heavy shadow on content | ✓ | ✓ | ✓ | ✓ |
| 8 · No guilt wording; no invented iOS APIs | ✓ | ✓ | ✓ | ✓ |

**Headline:** the implementation is a warm beige/green system; the spec is a cool green canvas with
black ink outlines and violet data. Every *structural* requirement passes (no glass, no neon, no
heavy shadow, no invented APIs) and every *visual* requirement fails. The single largest cause is
that there is no token layer — every value is typed inline in the view.

---

## 2 · Overview — done / `.debriefDone` state

Rendered by `OverviewDebriefDone()` at `MokoRootView.swift:126` when `OverviewMode` is `.debriefDone`
(`Mokonavigation.swift:12`).

### 2.1 What the code does

Title row → section label "Mission" → mission card containing a 42 pt checkmark disc, "No Active Quest",
"All quests completed!", one body paragraph, and a full-width countdown band. Then the same Growth
section as the normal Overview.

### 2.2 Layer tree vs §4

| §4 node | Implemented | Note |
|---|---|---|
| `Frame/Screen.Overview` | ✓ | `OverviewDebriefDone.swift:12` |
| `BG/Canvas` (gradient) | ✗ | flat `MokoTheme.limeBackground`, declared `:27` |
| `Vector/Bush`, `Vector/Leaf` | ✗ | no decorative vectors anywhere in the target |
| `Header/Title` | ✓ | `:83` |
| `Avatar/User` | ✓ | 47 pt, see §2.3 |
| `Section/Mission` | ✓ | label reads "Mission" |
| `Card/Mission` → `State/Empty` | ~ | exists, but carries an **unlisted** checkmark disc and "All quests completed!" headline |
| `Countdown/NextQuest` | ✗ | present as a band, but pinned **centre-bottom in its own grey box**, not trailing-bottom inline |
| `Section/Progress` | ~ | label reads "Growth", not "Progress" (`:208`) |
| `Card/Progress.Insights` | ✗ | white, not lavender; no `h 140` |
| `Card/Progress.CalmDown` | ✗ | white, not lavender |
| `Nav/Bottom` | n/a | supplied by native `TabView` — see §6.1 |

### 2.3 Token deltas

| Element | Spec | Code | Line |
|---|---|---|---|
| Canvas | `canvas.top` → `canvas.bottom`, 180° gradient | `MokoTheme.limeBackground` flat | `:27` |
| Card shell | `radius.card` + `stroke.card` of `stroke.ink` | radius 16, **no stroke**, shadow `black 3%` r8 y2 | `:188-191`, `:281-283` |
| Card fill | `surface.white` | `Color.white` ✓ value, wrong token name | `:188` |
| "No Active Quest" | `title2` in `state.emptyTitle` | 22 Bold in `primaryGreen` (#1B422F) | `:120-124` |
| Body | `body`, two lines max | 16 Regular, centred, 3 lines | `:151-156` |
| "All quests completed!" | **not in spec** | 21 Semibold | `:142-147` |
| Checkmark disc | **not in spec** | SF `checkmark.circle.fill` 42 pt + 10% wash | `:127-139` |
| Countdown label | "New quest in" → `caption`, `text.muted` | "New quests in" 14 Regular | `:166-168` |
| Countdown value | `countdown.value`, live every 60 s | literal `"12 hrs 48 mins"`, `timerBlue` (#0A84FF, `:31`) | `:169` |
| Countdown container | plain HStack, trailing-bottom | grey #F5F5F7 band, radius 12, vertical 13 | `:161-183` |
| Progress cards | `surface.lavender` | `Color.white` | `:281-283`, `:340-342` |
| Numbers (78 / 18) | `numeral` in `data.numeral` | 44 Bold `.rounded` in `primaryGreen` | `:261`, `:320` |
| Radar | `data.violet` 35% fill, `violet.deep` stroke `stroke.data`, dots `data.node` 3 pt | green radial gradient, 2.4 pt green stroke, 8 pt dots | used `:273-274`; chart is shared, `Overview.swift:499-588` |
| Bars | 8 bars, w6, r3, gap 8, ascending opacity, last bar `violet.deep` | 6 bars, w5.7, r1.5, gap 10, single green | used `:332`; chart is shared, `Overview.swift:604-635` |

### 2.4 States

`State/Empty` is implemented as a whole screen rather than a variant of `Card/Mission`. Consequences:

- The countdown, the recovery copy and the checkmark cannot be reused by the `.todo` screen.
- `Overview.swift:221-250` defines its own `emptyMissionContent` ("No Active Quest" + an
  "Explore Quests" pill) that **is never referenced by the body** — a second, unreachable empty state.
  Two implementations of the same spec node, neither matching §6.3.

### 2.5 Fix order

1. **Add the token layer.** Extend the existing `MokoTheme` (`startScreens/MokoTheme.swift:10`) with the
   §0 names and replace the five `private let` constants in this file. Nothing else is safe to do first.
2. **Add `moco.stroke.card`.** One `.overlay(RoundedRectangle(cornerRadius: 22).stroke(ink, lineWidth: 2))`
   on the card shell — closes acceptance item 1 for all three Overview screens at once.
3. **Replace the canvas** with a vertical `LinearGradient` of `canvas.top` → `canvas.bottom`.
4. **Delete `emptyMissionContent`** from `Overview.swift` and fold `State/Empty` into `Card/Mission`
   as a variant, using `state.emptyTitle` and the trailing-bottom countdown.
5. **Wire the countdown** to the real next-mission boundary; the literal at `:169` is the only reason
   it cannot ship.
6. **Recolour the data elements** to `data.numeral` / `data.violet` / `data.grid` / `data.node`, and
   set the progress cards to `surface.lavender`.
7. **Add `Vector/Bush` and `Vector/Leaf`** as `Shape`s behind `Safe/Content`, `accessibilityHidden(true)`.

---

## 3 · Overview — resumed state

`OverviewResumeScreen(quest:onSlideResume:onStartDebrief:)`, `OverviewResumeScreen.swift:12`,
rendered at `MokoRootView.swift:120` when `OverviewMode` is `.resume`.

### 3.1 Relationship to `Overview.swift`

It is a **near-verbatim copy** — palette, header, mission card, Growth section and both charts are
duplicated, not shared. The diff is confined to: no `mission` parameter, `quest?.title` instead of the
resolved mission, a local `isResumeCompleted` flag, the slider label, and `NavigationLink` to profile
instead of a sheet.

**This is the correct place to stop duplicating.** One `Overview(mode:)` with `OverviewMode` driving the
card variant would remove ~340 lines and fix the deltas once.

### 3.2 Deltas beyond §2.3

| Element | Spec | Code | Line |
|---|---|---|---|
| Slide label | `moco.type.slider`, fades 45→60% of travel | "Slide to resume", 15 Medium, always visible | `:219-223` |
| Slide state | `Ready` at ≥78% travel | fires at 70% (`maxDrag * 0.7`) | `:247` |
| Completion | track flash → card crossfade to `State/Empty` | sets `isResumeCompleted`, swaps to "Resume Debrief" + mic | `:250-252` |
| Header avatar | `Control` opening profile | `NavigationLink` into `ProfileOverView` | `:103-120` |

Everything else in §2.3 applies unchanged — same 16 pt radius, same 47 pt avatar, same missing stroke.

### 3.3 Semantic note

The spec defines exactly one slider — `Control/Slide`, label "Slide to Complete". A resume affordance
is a legitimate second variant, but it must be registered as `Control/Slide.Resume` with its own label
token rather than inherited silently. §0 forbids aliasing two names to one value; the inverse (one
component with two unregistered labels) is what exists today.

---

## 4 · Debrief — conformance to the master scale

`Questdebrief.swift` is the deepest screen in the app (1,554 lines). The master prompt only specifies
the Overview, so this section audits the **scale, type, radius and colour law** it implies, which §0
says applies to every line.

### 4.1 Palette

`DebriefStyle` (`:27-37`) declares ten colours. **None matches a registry token**, and the set is a
different temperature — cream, sand, rust and border tones against a spec built on green canvas,
black ink and violet data:

| `DebriefStyle` | Literal | Nearest registry token | Verdict |
|---|---|---|---|
| `screenBg` | `MokoTheme.limeBackground` | `canvas.top` | ~ value, wrong token, no gradient |
| `green` | #365948 | — | ✗ off-registry |
| `deepGreen` | #1B422F | `stroke.ink` / `text.title` | ✗ wrong hue family |
| `title` | `MokoTheme.titleBrown` | `text.title` | ✗ brown where spec is near-black |
| `subtext` | #6F6762 | `text.body` | ✗ warm grey |
| `cream` | #FBF7EE | — | ✗ not in registry |
| `border` | #EAE0CC | `data.grid` | ✗ warm vs cool |
| `sand` | #E9E2D6 | — | ✗ not in registry |
| `rust` | #B04E3A | — | ✗ introduces a 6th hue |
| `mint` | #CBE6D3 | — | ✗ not in registry |

A further **15 `Color(red:…)` literals** are used directly in the file, bypassing `DebriefStyle`
entirely — the same failure mode as the Overview, one level deeper.

### 4.2 Type scale

Eleven distinct sizes are in use: `11, 12, 13, 14, 15, 16, 17, 18, 20, 28, 32`.

| Registry | Used in debrief | Mismatch |
|---|---|---|
| `title1` 32 | 32 ✓ | weight/tracking unverified |
| — | 28, 20, 18, 14, 11 | **not in registry** |
| `title2` 22 | — | not used |
| `section` 19 | — | not used |
| `cardTitle` 17 | 17 ✓ | |
| `body` 15 | 15 ✓ | |
| `caption` 13 | 13 ✓ | |
| — | **12 (×10 occurrences)** | the dominant body size, and **§8 forbids anything below 13 pt** |

Twelve point is used ten times — more than any conforming style. This is a direct, single-line-per-site
breach of acceptance item 3.

### 4.3 Radii

| Used | Count | Registry |
|---|---|---|
| 24 | ×6 | ✗ (`radius.card` is 22) |
| 30 | ×2 | ✗ |
| 18 | ×3 | ✗ |
| 14 | ×2 | ✓ `radius.inner` |
| 12 | ×1 | ✗ |
| 2.5 | ×1 | ✗ |

Only one of six radii is registered. The card radius is systematically 2 pt larger than `radius.card`.

### 4.4 Spacing grid

`moco.scale.base` is 4, so every inset should be a multiple of 4. Observed horizontal/top insets:
`18 (×5), 20, 16, 15, 12, 10, 9, 8, 7, 2`.

`15`, `18`, `9`, `7` and `2` all sit off the grid, and `moco.space.page` (24) never appears. The screen
is running on a 1–2 pt hand-tuned scale, not the 4 pt base — which is why the debrief and the Overview
feel like two different products despite sharing a green canvas.

### 4.5 What does conform

- No glass, blur or neon on content (item 7) ✓
- No heavy shadow — the debrief is the flattest screen in the app ✓
- Motion uses real `.spring(response:dampingFraction:)` and `Task.sleep`, no invented APIs ✓
- Scores are presented without guilt or medical wording ✓
- Reduce Motion is honoured for the waveform and typing dots ✓

### 4.6 Fix order

1. Import the `MocoTheme` token layer from §2.5 step 1 and **delete `DebriefStyle`** — map `deepGreen`
   → `text.title`, `subtext` → `text.body`, `border` → `data.grid`, and retire cream/sand/rust/mint.
2. Raise the ten 12 pt and the one 11 pt sites to `caption` — one mechanical pass, closes item 3.
3. Snap radii to `radius.card` / `radius.inner` only.
4. Snap insets to the 4 pt grid; introduce `moco.space.page` for the outer inset.
5. Then re-derive the card shell from `Card/Base` §6.2 so the debrief and the Overview inherit the same
   2 pt `stroke.ink` and elevation.

---

## 5 · Systemic gap

Both surfaces fail for the same reason, and it is not a styling detail:

> **There is no token layer.** `ColorTokens` (`Models/ColorTokens.swift:9`) exists and is referenced only
> by itself; `MokoTheme` (`startScreens/MokoTheme.swift:10`) holds five warm colours that match no registry
> token; and each screen then declares its own `private let` palette on top of it. The debrief declares a
> third, `DebriefStyle`.

Consequences:

- Changing a colour means editing 3–4 files, which is why the Overview and the debrief have drifted to
  different greens.
- The §0 naming law cannot be satisfied by construction — no name exists to reference.
- Acceptance item 1 (one stroke rule for **all** cards) is unimplementable until cards share a shell.

The first commit of any design work should be `MocoTheme.swift` + `MokoCard` shell, and nothing else.
That single change converts ~20 of the deltas above into one-line edits.

---

## 6 · Two open questions for the designer

Not defects — genuine ambiguity in the prompt.

**6.1 The navigation bar.** §6.7 specifies `Nav/TabBar` as a floating glass capsule of three tabs plus
a separate 56 pt search circle, with a 96 pt bottom inset. The app renders a native `TabView` with
**four** tabs (Overview, Quests, Relax, Explore) and no separate search circle — `MokoRootView.swift:15`.
Either the spec predates the Explore tab, or the custom tab bar is still to be built. The prompt's own
§8 item 7 forbids glass on *content*, which the tab bar is exempt from, so this is a real fork.

**6.2 The empty state.** The prompt defines `State/Empty` as a variant of `Card/Mission`. The app ships
it as a separate screen. Which is authoritative — the variant (my reading of §4 and §9 `States`), or the
screen?

---

*Produced from a read-only pass. No project file was modified.*
