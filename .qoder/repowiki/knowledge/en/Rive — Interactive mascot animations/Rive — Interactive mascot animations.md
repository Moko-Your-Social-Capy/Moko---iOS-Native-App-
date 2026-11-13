---
kind: external_dependency
name: Rive — Interactive mascot animations
slug: rive-ios
category: external_dependency
category_hints:
    - framework_behavior
scope:
    - '**'
source_files:
    - Moko/RiveProjects/BadgeUnlock/rive.yaml
    - Moko/RiveProjects/MokoMascotRive/rive.yaml
    - Moko/.agents/skills/rive-animation/tools/frame_diff.py
---

### Rive (rive-ios)
- Role: interactive mascot animations alongside Lottie; each project lives under `Moko/RiveProjects/` with its own `scene.rml`, `rive.yaml`, and optional assets (e.g. BadgeUnlock, MokoCompleteRive, MokoMascotRive, MokoMeditationRive, MokoWelcomeRive).
- Build note: the `.agents/skills/rive-animation/` directory contains helper tools (`frame_diff.py`, `thin_keys.py`) used to process Rive assets before embedding.