MOKO Lottie JSON exports

Each .json file was extracted from its corresponding .lottie archive.
The JSON animation data was preserved; no redesign or re-encoding was performed.

Add the desired .json files to Xcode and ensure:
1. Target Membership includes the Moko app target.
2. Build Phases > Copy Bundle Resources includes the JSON file.
3. In code, load by the exact filename without the .json extension, e.g.:
   LottieAnimation.named("confetti")

Notes:
- Confetti contains 5 internal composition assets (precomps), not external image files.
- Empty.lottie has one root layer; inspect/preview it before using because its filename may indicate intentionally empty content.
- These exports are standard Lottie JSON, but individual After Effects features may still need runtime validation in Lottie iOS.
