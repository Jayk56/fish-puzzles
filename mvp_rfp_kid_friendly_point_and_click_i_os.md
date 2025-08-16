# MVP RFP: Kid‑Friendly Point‑and‑Click Adventure (iOS)

## 1) Overview & Goals
- Whimsical, story‑driven 2D adventure for ages 4–9 ("Freddi Fish–style"): exploration, simple inventory puzzles, friendly characters.
- Priorities: kid safety/compliance, delightful art/VO, intuitive touch UX, high performance on modern iPhone/iPad.
- MVP aims to validate core loop, usability, and production pipeline in a tightly scoped build.

## 2) MVP Scope of Work
**Design**
- Narrative slice covering **2 locations/chapters**; **20–35 min** first‑time play.
- **6–8 core puzzles** with **variable item placements (2–3 variants)** for light replayability.
- Contextual **Hint/Skip** system; simple quest log for parents.

**Production**
- Optional micro‑collectibles (≤8) that do not block completion.
- Kid‑safe failure states only (no timers/pressure).

**Art & Animation**
- Hand‑drawn 2D: **6 backgrounds**, **10–12 characters** (idle/talk/emote), lightweight FX.
- Compact **Art Bible** (palettes, line weight, UI motifs) + UI kit.

**Audio**
- **2 music cues** (+ win/lose stingers); **VO for all dialogue** with concise line count; caption/subtitle files.
- SFX starter library (taps, pickups, UI, ambient) with loudness normalization.

**Engineering**
- Unity 2D (preferred) targeting **iOS/iPadOS 16+**; **universal app**; **60 FPS** target; **≤500 MB** at download.
- **Touch only** interactions; haptics where helpful.
- **Save system** (auto + manual slot) with **iCloud sync**; offline‑first.
- Settings: subtitles on/off, master volume, text size preset.

**QA & Compliance**
- Test on recent iPhones (mini → Pro Max) + iPads; accessibility & performance passes.
- Privacy/compliance checks; App Store Kids Category readiness checklist.

**Live‑Ops Handoff**
- Build pipeline scripts, developer README, and post‑launch triage plan (hotfix process, crash logging).

## 3) Platform & Technical Requirements
- Engine: **Unity LTS** (or equivalent 2D engine with parity).
- Apple Silicon simulator support.
- Integrations: **none required for MVP**; Game Center achievements **post‑MVP**.
- **No third‑party ads/trackers**; minimal first‑party analytics (see Privacy).

## 4) Gameplay & UX Requirements
- **Tap‑to‑move**, hotspot interactions; **drag‑and‑drop inventory**.
- Scalable UI; tap targets **≥44 pt**; dyslexic‑friendly font option; color‑contrast compliant.
- Kid‑safe UX: gentle guidance; clear affordances; persistent Hint button.
- **Localization‑ready** text/subtitle system (MVP ships **English**; strings externalized; RTL‑capable framework).

## 5) Art & Audio Direction
- Bright, friendly undersea/animal (or similar) world; cohesive palettes and shape language.
- 2D rigging or frame‑by‑frame for acting; lip‑sync for VO.
- Audio deliverables: music stems, per‑line VO files, SFX packs.

## 6) Compliance, Privacy, Safety
- **COPPA** and **App Store Kids Category** compliant; **GDPR‑K friendly**.
- **Parental gate** for outbound links/ratings; **no social sharing**.
- Analytics limited to **anonymous, aggregate gameplay events**; opt‑in where required.

## 7) Deliverables (MVP)
- **GDD (concise)** + puzzle flowcharts; **Art Bible (lite)**; **UI kit**; content list; VO scripts.
- Source repo; build/CI scripts; **test plans + results**.
- Localized strings pipeline; sprite/atlas exports; audio packs.
- TestFlight builds + release candidate; submission metadata.

## 8) Acceptance Criteria
- Player completes MVP narrative slice end‑to‑end without assistance in **≤35 min**; all puzzles shippable with hints.
- App passes device, performance, and accessibility checks; size **≤500 MB**; runs **60 FPS target**.
- Kids Category compliance verified; parental gate functional; analytics limited and documented.
- iCloud save sync confirmed (two devices, same Apple ID); offline play supported.

## 9) Out‑of‑Scope / Post‑MVP
- Additional chapters/locations, expanded collectibles, Game Center achievements, multi‑language VO, live events.
- Monetization experiments or social features.

