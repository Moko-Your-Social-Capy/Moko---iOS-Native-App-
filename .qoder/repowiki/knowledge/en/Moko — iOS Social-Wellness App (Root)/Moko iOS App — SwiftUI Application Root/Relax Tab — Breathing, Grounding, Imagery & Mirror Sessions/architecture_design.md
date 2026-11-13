Single-screen SwiftUI module rooted at `RelaxScreen.swift`, which owns a `NavigationStack` driven by the typed `RelaxRoute` enum (`breathing`, `session`, `guideSession`, `guideComplete`, `mirrorPrep/Timer/Complete`). Each exercise lives in its own subfolder:
- `BoxBreathing/` — self-contained timer with an animated box-drawing `Edge` shape, phase/state machine, and completion animation.
- `Breathing/` — generic timed session using a Rive `Worker` mascot with inhale/exhale rhythm.
- `Grounding/` — step-by-step 5-4-3-2-1 sensory exercise with per-step selection.
- `ImageryGuide/` — list + session + complete flow sharing an `ImageryGuideStore` via `.environment()`; also exposes a standalone `RelaxFlow` view for use outside the main tab.
- `MirrorReflection/` — landing screen plus camera/mirror preparation and timer flows.

`RelaxScreen` is the only entry point into the unified navigation stack; child screens communicate back through callbacks (`onFinish`, `onContinue`, `onSelectOption`) or by pushing routes onto `navigationPath`. Shared UI helpers (`RelaxDetailSheet`, `RelaxSessionSheet`, `RelaxSessionIcon`, `BreathingDotsIcon`) live in the root file. Session persistence goes through `modelContext.logCalmDown(...)` from SwiftData, and the palette is defined inline per screen (e.g. `BBColor`, local `screenBg`/`cardGreen` constants) rather than centralized here.