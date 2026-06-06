# Baby Feeding — Rollout Runbook

How to put the app on both phones and confirm the shared sync works. The two
phones auto-pair: they share one `AppConfig.familyID` baked into the app, so no
setup beyond installing.

## Prerequisites
- Xcode (with your paid Apple Developer account signed in: Xcode ▸ Settings ▸ Accounts).
- Both iPhones + a cable.
- The backend is already deployed (`https://baby-feeding-sync.johnson-books.workers.dev`); nothing to do there.

## Install on a phone (repeat for each phone)
1. Open `BabyFeeding/Baby_Feeding.xcodeproj` in Xcode.
2. Plug in the phone; select it as the run destination (top bar).
3. Target **Baby_Feeding** ▸ Signing & Capabilities ▸ set **Team** to your account (automatic signing).
4. Press **Run** (⌘R). The app installs and launches. With a paid account it stays valid ~1 year.
5. First launch asks for notifications — Allow (the Feeding tab uses reminders).

> **Your wife's phone has the old version.** Installing over it keeps her data —
> on first launch the app imports her existing feeding history and pushes it to
> the shared log (verified in the simulator). Do hers, then open the app on your
> phone; her history should appear there too within a few seconds.

## Acceptance checklist (do this once both are installed)
- [ ] **Feeding sync**: log a feeding on phone A → open/foreground the app on phone B → it appears within a few seconds (sync runs on launch and on foregrounding).
- [ ] **Diaper sync**: on the Diapers tab, tap 💧 on phone B → phone A shows the updated "wet today" count.
- [ ] **Edit propagates**: change a feeding's time on one phone → reflected on the other.
- [ ] **Delete propagates**: delete an entry on one phone → it disappears on the other.
- [ ] **Messaging is off**: logging a feeding does NOT open Messages (it's opt-in — Settings ▸ Announce Feedings).
- [ ] **History migrated**: on your wife's phone, her pre-existing feedings are present (and now visible on your phone too).
- [ ] **Reminder fires**: after the configured interval, the "Time to Feed" notification appears.

## If something's off
- **Not syncing?** Check the phone has internet. Sync triggers on app launch and when you bring it to the foreground — try backgrounding and reopening.
- **See the live data**: `cd server && ./peek.sh` prints the shared feeding + diaper log in local time.
- **Fix a bad entry so both phones update**: tombstone it (don't hard-delete) —
  ```bash
  NOW=$(($(date +%s)*1000))
  npx wrangler d1 execute baby-feeding --remote --command \
    "UPDATE feedings SET deleted=1, updated_at=$NOW WHERE id='<full-id>'"
  ```
  (Examples for time corrections and diapers are in `server/peek.sh`.)
- **After any backend change**: redeploy (`cd server && npm run deploy`) then `./smoke.sh` to confirm the API still works.
