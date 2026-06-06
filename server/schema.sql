-- Baby Feeding sync — shared family feeding log (Cloudflare D1 / SQLite)
--
-- One row per feeding. Records are never hard-deleted: a delete sets deleted=1
-- so every device converges on the same state (tombstone sync). Conflicts
-- resolve last-writer-wins by updated_at.

CREATE TABLE IF NOT EXISTS feedings (
  id         TEXT PRIMARY KEY,          -- client-generated UUID (stable across devices)
  family_id  TEXT NOT NULL,             -- shared key identifying one family's log
  fed_at     INTEGER NOT NULL,          -- epoch milliseconds of the feeding
  note       TEXT,                      -- optional (e.g. "bottle"/"breast"/who) — reserved for future UI
  deleted    INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL           -- epoch ms of last write; used for last-writer-wins
);

CREATE INDEX IF NOT EXISTS idx_feedings_family ON feedings (family_id);
CREATE INDEX IF NOT EXISTS idx_feedings_family_updated ON feedings (family_id, updated_at);

-- Diaper changes (first few weeks): same sync model as feedings, plus a kind.
CREATE TABLE IF NOT EXISTS diapers (
  id          TEXT PRIMARY KEY,          -- client-generated UUID
  family_id   TEXT NOT NULL,
  occurred_at INTEGER NOT NULL,          -- epoch milliseconds of the change
  kind        TEXT NOT NULL,             -- "pee" | "poop"
  deleted     INTEGER NOT NULL DEFAULT 0,
  updated_at  INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_diapers_family ON diapers (family_id);
CREATE INDEX IF NOT EXISTS idx_diapers_family_updated ON diapers (family_id, updated_at);
