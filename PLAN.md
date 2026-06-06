# Baby Feeding — Plan & Queue

Living document. Read this at the start of every session before proposing next work.

## TL;DR (current state)

- **Status**: real app in family use. iOS (SwiftUI) + a Cloudflare Worker/D1 sync backend.
- **Active slice**: **Shared Family Log** — done in code, **pending real-device test** by Chris + wife (two phones, separate Apple IDs).
- **Last commit**: see `git log`. GitHub remote `cjjknight/Baby-Feeding`.
- **Open issues**: none tracked. (One pre-existing bug — edit-sort — was fixed in this slice.)
- **Moved into Forge**: 2026-06-06 from `_archive/legacy_pre_forge/iOS_Apps_2024/Baby_Feeding/`.

## Vision in one line
The simplest possible baby-feeding tracker for two parents — one tap to log, always in sync across both phones, nothing else to think about. (Built because App Store trackers are overcomplicated.)

## Working agreement
Forge workspace defaults (see `~/.claude/projects/-Users-christopherjohnson-Desktop-Personal-Recreation-Forge/memory/feedback_working_defaults.md`): slices not "Day N"; one upfront approval then autonomous; single end-of-slice test. **Simplicity is the product** — resist adding fields/screens; the value is that it's dead easy for the wife to use.

## Architecture

**iOS app** (`Baby_Feeding/`, SwiftUI, iOS 17.5+, Xcode project objectVersion 56):
- `FeedingStore.swift` — single source of truth. Holds `[Feeding]`, persists to UserDefaults, and syncs. Mutations are optimistic-local-then-background-push; pulls merge last-writer-wins by `updatedAt`; deletes are tombstones so both phones converge. Also contains `AppConfig` (family ID + backend URL) and `FeedingSyncService` (the HTTP client). **All new data-layer code lives in this one file on purpose** — the project is not filesystem-synchronized (objectVersion 56), so adding new files means editing `project.pbxproj`. Reuse this file (or do pbxproj surgery deliberately) rather than scattering new files.
- Views: `ContentView` (wires store + triggers `syncNow()` on appear/foreground), `TimerView` (the big one-tap button + elapsed clock + reminder notification), `FeedingsListView` / `EditFeedingView` (manual add/edit/delete), `TimelineView` + `SummaryStatsView` (read-only displays), `SettingsView` (interval + opt-in messaging + contacts).
- `SharedDataModel` — feeding interval (now persisted), selected contacts, and `messagingEnabled` (the opt-in for the announce-feeding text).

**Backend** (`server/`, Cloudflare Worker + D1 — same stack as book-bingo):
- Deployed: **https://baby-feeding-sync.johnson-books.workers.dev**
- D1 database `baby-feeding` (id `fdccb32b-3bb5-4eff-ae31-011f2b2effb9`). Schema in `server/schema.sql`.
- API: `GET /api/health`, `GET /api/feedings?family=&since=`, `POST /api/feedings` (upsert, LWW). One shared `family` key pairs the two phones (baked into `AppConfig.familyID`) — no accounts.
- Deploy with `cd server && npm run deploy`. Data is separate from code; deploys never touch the log. Back up with `npm run db:backup`.

## Verification
- **Build/run a simulator** (no GUI needed): `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Baby_Feeding.xcodeproj -scheme Baby_Feeding -destination 'platform=iOS Simulator,name=iPhone 15' build CODE_SIGNING_ALLOWED=NO`, then `xcrun simctl install/launch` + `xcrun simctl io booted screenshot`.
- **Backend round-trip**: curl the API (see commit history for the create/edit/LWW/tombstone/since checks).
- **This slice's status**: build succeeds; pull→merge→display verified in the simulator against the live server. **Push-from-device path is contract-verified (curl) but not yet exercised by a real tap — confirm on a real phone.**

## Open issues
- None tracked.

## Queue (next slices, top-priority first)
- **Real-device acceptance** (Chris + wife): install on both phones, log from each, confirm both stay in sync; confirm the opt-in messaging toggle behaves; confirm legacy history migrated for the phone that had the old app.
- **App icon / polish** (optional) — currently a prototype bundle id (`CJProtoType.Baby-Feeding`).
- **Per-feed source** (deferred, only if wanted) — bottle vs breast vs who-fed. The backend already carries an unused `note` column for this; intentionally no UI yet to keep logging one-tap.
- **"Who's overdue" / both-parent reminders** (deferred) — reminders currently fire per-device off the shared last-feeding.

### Parking lot
- Replace the hardcoded baby name ("Troy") in the announce-feeding message with a Settings field.
- A real "pair a family" flow instead of a baked-in family ID (only needed if shared beyond the two of them).

## How to update this file
- When starting a slice, mark it `**[in progress]**`. When done, move it to `## Done` with date + commit.

## Done
- 2026-06-06 — **Backup + consolidation**: pushed the unpushed final commit (`00d02ff`, was on a detached HEAD) to GitHub; moved the project from `_archive` into `Forge/BabyFeeding/` as an active project; added PLAN.md + CLAUDE.md.
- 2026-06-06 — **Shared Family Log slice**: added the Cloudflare Worker + D1 sync backend; refactored all feeding data into `FeedingStore` with optimistic-local + background sync (LWW, tombstones, legacy migration); fixed the edit-sort bug (editing a feeding used to sort ascending and make the main timer count from the oldest feed); made the announce-feeding text opt-in (off by default) via a Settings toggle; persisted the feeding interval across launches. Verified: simulator build + live server pull/merge/display.
