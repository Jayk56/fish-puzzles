# Repository Guidelines

## Project Structure & Modules
- `fish-puzzles/`: App source (Core, Scenes, Systems, UI, Utilities, Resources).
- `fish-puzzlesTests/` and `fish-puzzlesUITests/`: Unit and UI tests.
- `Assets/`: Raw art/audio inputs; generate processed atlases before committing.
- `Scripts/`: Tooling (e.g., `generate_atlases.py`).
- `Configuration/`, `ProcessedAssets/`, `.build/`: Build/config outputs (excluded from lint where appropriate).

## Build, Test, and Development
- `make setup`: Install SwiftLint/xcbeautify.
- `make build` | `make run`: Build or run in iOS Simulator.
- `make test` | `make test-unit` | `make test-ui`: All, unit-only, or UI-only tests.
- `make lint` | `make format`: Lint with SwiftLint; format with SwiftFormat (if installed).
- `make atlases`: Generate texture atlases from `Assets/`.
- `make clean` | `make release` | `make archive`: Clean artifacts; optimized build; create Xcode archive.
- Tip: Open `fish-puzzles.xcodeproj` to edit targets; simulator target defaults to iPhone 16.

## Coding Style & Naming
- Swift 5.x; enforce via `.swiftlint.yml` (e.g., line length warn 100/error 120, function/type/file length budgets, cyclomatic complexity caps).
- Prefer `private` by default; mark classes `final` when not subclassed.
- Names: Types `PascalCase`; methods/properties `camelCase`; constants `UPPER_SNAKE_CASE` when global.
- One primary type per file; group by feature folder; use `// MARK:` for navigation.

## Testing Guidelines
- Frameworks: XCTest (unit) and XCUITest (UI).
- Location: `fish-puzzlesTests/` and `fish-puzzlesUITests/`.
- Naming: Test files end with `Tests.swift`; methods start with `test...` and assert one behavior.
- Run: `make test`, or focus with `make test-unit` / `make test-ui`.
- Coverage/profiling: `make profile` enables code coverage and sanitizers.

## Commit & Pull Requests
- Commits: Prefer Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`). Keep scope small and messages imperative (e.g., `feat: add inventory persistence`).
- PRs: Include clear description, linked issue, screenshots/video for UI changes, and checklist: build passes (`make build`), tests pass (`make test`), lint clean (`make lint`).

## Security & Configuration
- Do not commit secrets or Apple IDs; CloudKit container is configured in Xcode capabilities.
- Large binaries: keep originals in `Assets/`; commit only processed outputs when necessary. Use `make atlases` to regenerate.
