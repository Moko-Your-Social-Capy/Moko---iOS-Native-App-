# Moko — Apple Foundation Models (AFM) layer

Requires iOS 26+ and a device with Apple Intelligence.

## Files

| File | What it holds |
|---|---|
| `MokoMissionBank.swift` | Shared types (`Stat`, `Difficulty`, `MissionTemplate`) and the 20-situation Mission Bank (scene, who, goal, age range, four per-stat follow-up questions). |
| `MokoAFM.swift` | `AFM.generate` helper (fresh session per call, retry, availability check), the `@Generable` output types, and all prompts for onboarding, quest cards and debrief. |
| `MokoServices.swift` | Onboarding scoring and insights, quest card service, daily mission planner, and the `DebriefEngine` state machine. |
| `MokoMissionInvention.swift` | Invents fresh daily missions with variety seeds, a Swift validator and an AFM review pass; falls back safely. |
| `AFMDebriefCoach.swift` | Bridge between AFM debrief intelligence and the existing `QuestDebriefScreen` UI via `DebriefCoaching`. |

All AFM files are located in `Moko/Features/AFM/`.

## Design rules

- **Swift does the logic, AFM does the language.** Score maths, weakest-stat choice, scheduling, difficulty and images are plain Swift. AFM writes analysis text, card text and questions, and extracts evidence from what the user said.
- **Fresh session per call.** The on-device model has a small context window (around 4k tokens), so every call gets a compact prompt. This also stops the debrief drifting into a chat.
- **User text is data.** It is wrapped in `<user_input>` / `<user_said>` tags and the prompts say never to follow instructions inside them.
- **Every AFM call has a fallback.** The app never blocks on the model.
- **No guessed scores.** If a stat has no evidence in the user's words, it gets no score.

## The five tasks

### 1. Onboarding insights
- `OnboardingScoring.scores(from:)` maps the 8 yes/no answers to the four stats, using the tags from the tagging PDF. Primary = 1.0, secondary = 0.4, Q8 for Presence = 0.6 (the PDF flags it as tentative). "Yes" always means the harder behaviour. Scores land between 25 and 90.
- `OnboardingInsightService.analyze(_:)` asks AFM for a 1–2 line note per stat: encouraging for strengths, gentle and specific for growth areas. Static fallback text is used if AFM fails.

### 2. Quest cards
- AFM writes the title, scene, who and goal.
- Difficulty comes from the user's choice (custom quests) or the bank tier (daily). The category image is fetched by the app from `card.category`.
- For custom quests, AFM first picks the closest of the bank situations in the user's category (`TemplateChoice`), then writes the card from the user's title and notes.

### 3. Voice debrief
`DebriefEngine` runs a fixed sequence and ignores input after `.finished`:

1. Greeting and main question.
2. User answers. AFM returns a confidence score and note, plus Courage and Clarity.
3. Follow-up 1 (Presence), then follow-up 2 (Warmth). Both come from the bank question, reworded around something the user said.
4. Follow-up 3 targets whichever stat has the weakest evidence so far.
5. Closing message tied to the event and goal. Final scores are an evidence-weighted average per stat.

Confidence means how well an answer matches the goal or question and shows the user really did it. Hedging lowers it slightly and assured, specific language raises it slightly. Change the rubric in `DebriefPrompts.analysisInstructions` if you want something else.

### 4. Daily missions from a custom quest
- `MissionPlanner.plan` gives one mission per day until the quest date. It ramps from easy up to the user's chosen difficulty inside the matched category. The last day rehearses the matched situation.
- `QuestCardService.dailyCard` turns each planned day into a card, generated when that day opens.
- Ramp days try `MissionInventor` first. If invention fails any check, they fall back to a reworded bank situation. The rehearsal day is never invented.

### 5. Mission bank
Everything pulls from `MokoMissionBank.swift`. Each invented or reworded mission keeps its bank `templateID`, so the debrief always has vetted follow-up questions.

## Keeping invented missions doable

1. **Anchor:** each invention must practise the same behaviour as its bank situation.
2. **Seeds:** Swift offers 3 formats and a tone per day (`VarietyPool`); the model adapts them.
3. **Validator:** `MissionValidator` checks length, single sentence, verb-first, title repeats, outcome-style goals and a blocklist.
4. **Review pass:** a low-temperature AFM call answers five yes/no checks (doable, single behaviour, follow-ups fit, believable, safe).
5. **Fail closed:** one retry with feedback, then fall back to the reworded bank situation.

