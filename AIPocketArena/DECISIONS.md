# Decisions Log — AI Pocket Arena

This document logs open decisions taken during the build of the AI Pocket Arena iOS app, adhering to standarddefaults and guidelines.

## 1. Spaced Repetition Scheduling: SM-2 Selected
- **Choice**: SM-2 over FSRS.
- **Rationale**: SM-2 is simpler, well-documented, deterministic, and doesn't require training weight calculations on device. The implementation is abstracted behind the `Scheduler` protocol, so FSRS can be easily added as an alternative option in a later iteration.

## 2. On-Device LLM Grader: Feature-Flagged OFF
- **Choice**: Deterministic grader by default; local LLM placeholder feature-flagged `ENABLE_LLM_GRADER = false`.
- **Rationale**: Shipping a 4GB GGUF model with a simple learning game introduces severe download size and runtime memory bottlenecks. The `DeterministicGrader` uses keyword coverage and fuzzy matching, achieving high accuracy with zero latency or battery overhead.

## 3. Font Integration: OFL Google Fonts
- **Choice**: Embed and bundle OFL-licensed Google Fonts (Syne, DM Mono, Inter) as assets.
- **Rationale**: This is compliant with OFL licensing rules for iOS bundling and matches the exact typography requirements in §8.

## 4. Game Center: Stubs Only
- **Choice**: Implement local high scores and stats; Game Center features stubbed out.
- **Rationale**: Complete Game Center integration requires developer account team setup and provisioning profiles in App Store Connect, which cannot be automated without user intervention. Local data persistence is handled robustly via SwiftData.

## 5. UI Theme: Classic Neon Fallback
- **Choice**: Dark Mode neon colors with glass overlays.
- **Rationale**: iOS 26 "Liquid Glass" materials require Xcode 26 beta SDKs. We use `#available(iOS 26, *)` progressive enhancement checks to fall back gracefully to premium Dark Mode card overlays on iOS 18+.
