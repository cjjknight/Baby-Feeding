# Baby Feeding — SwiftUI app + Cloudflare sync backend

A deliberately-minimal baby-feeding tracker for two parents on separate phones. One tap logs a feeding; both phones stay in sync. **In real family use.**

> **For current state, the queue, and the deployed backend URL, read `PLAN.md`.** This file documents stable conventions only.

## The one rule: keep it simple
This app exists *because* App Store trackers are overcomplicated. The value is that it's effortless for a tired parent at 3am. Before adding any field, screen, or option, assume the answer is no. One-tap logging is sacred.

## Layout
```
BabyFeeding/
├── PLAN.md
├── Baby_Feeding.xcodeproj        # objectVersion 56 — NOT filesystem-synchronized
├── Baby_Feeding/
│   ├── Baby_FeedingApp.swift      # @main
│   ├── FeedingStore.swift         # ← data layer: model + store + sync + AppConfig
│   ├── SharedDataModel.swift      # interval, contacts, messagingEnabled
│   ├── Utility.swift              # shared dateFormatter
│   └── Views/                     # ContentView, TimerView, FeedingsListView,
│                                  #   EditFeedingView, TimelineView,
│                                  #   SummaryStatsView, SettingsView, Contact*
└── server/                        # Cloudflare Worker + D1 sync backend
    ├── src/index.js               # REST API
    ├── schema.sql                 # feedings table
    └── wrangler.toml              # live database_id wired in
```

## Conventions

### Adding Swift files — avoid it
The Xcode project is `objectVersion 56` (not Xcode-16 filesystem-synchronized), so a new `.swift` file on disk is **not** compiled until it's referenced in `project.pbxproj` (PBXBuildFile + PBXFileReference + group + Sources phase). To dodge fragile pbxproj editing, **new data-layer code goes into the existing `FeedingStore.swift`**. Only do pbxproj surgery when a new file is genuinely warranted, and verify with a simulator build immediately after.

### Data + sync
- `FeedingStore` is the single source of truth. Views never read/write UserDefaults or the network directly — they call store methods (`logFeeding`, `updateFeeding`, `deleteFeeding`) and read `activeFeedings` / `activeDates` / `lastFeedingDate`.
- One canonical sort: `activeFeedings` is newest-first. Do not re-sort feeding arrays in views (that was the original edit-sort bug).
- Sync is optimistic-local-then-background-push; pulls merge last-writer-wins by `updatedAt`; deletes are tombstones (never hard-delete client-side). Trigger a pull with `store.syncNow()` on appear and on `scenePhase == .active`.
- The two phones are paired by a shared `AppConfig.familyID` baked into the app — there are no accounts. Changing that ID starts a fresh, separate log.

### Backend
- Same stack/discipline as the `book-bingo` project: Worker + D1, plain `wrangler`, no build step. App code and the D1 data are separate; `npm run deploy` never touches the log. Back up with `npm run db:backup` before any schema/data change.

## Build / run / verify (no Xcode GUI required)
```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
# build for simulator
xcodebuild -project Baby_Feeding.xcodeproj -scheme Baby_Feeding \
  -destination 'platform=iOS Simulator,name=iPhone 15' build CODE_SIGNING_ALLOWED=NO
# run + screenshot
xcrun simctl boot "iPhone 15"; xcrun simctl install booted <path>/Baby_Feeding.app
xcrun simctl launch booted CJProtoType.Baby-Feeding
xcrun simctl io booted screenshot /tmp/shot.png
# backend
cd server && npm run dev          # local
cd server && npm run deploy       # live
```

## Working agreement
Slice + Task framing. One upfront approval, then autonomous; single end-of-slice test. GitHub remote: `cjjknight/Baby-Feeding`.
