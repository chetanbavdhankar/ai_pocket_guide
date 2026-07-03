# AI Pocket Arena — iOS Learning Game

An offline-first, native iOS game that drills users on AI/LLM technical terms to build active-recall mastery.

## Features
- **8 Game Modes**: Flash Recall, Rapid Fire MCQ, Match Pairs, Cloze Recall, Connections, Scenario Tradeoffs, Depth Ladder Interview Sim, and Boss Round Gauntlet.
- **Spaced Repetition Engine**: Built-in SM-2 scheduler algorithm that prioritizes due/weak concepts.
- **Achievements System**: 20+ unlockable badges, streaks, and XP level progression.
- **Local Persistence**: Full SwiftData support for progress records, profile stats, and settings.
- **Searchable Browser**: Filter and search the 35+ core technical terms from tokenization to scaling laws.

## Project Structure
- `App/`: @main entry, root TabView structure.
- `Core/`: Shared schemas, database entities, design tokens, session builders, and grading interfaces.
- `Features/`: Feature-folded MVVM views, view models, and layouts.
- `Resources/`: Seed JSON and bundled font assets.
- `Utilities/`: Audio cues (SFX) and haptics managers.

## Seeding & Validation
The bundled term bank is stored at `AIPocketArena/Resources/concepts.json`.
To add new concepts:
1. Ensure the new entry matches the `Concept` schema: `id`, `term`, `category`, `difficulty`, `oneLiner`, `explanation`, `interviewQuestion`, `modelAnswer`, `distractors`, `cloze`, `tradeoff`, `tags`, `related`.
2. Ensure all listed `related` concept IDs exist.
3. Validate that `oneLiner` is 140 characters or less.
4. Validation runs automatically at launch in debug builds.
