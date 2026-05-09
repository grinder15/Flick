# Library Scan Architecture

## Overview

The scanner uses two tiers, prioritized by availability and performance:

1. **Android `MediaStore` Query** (primary, Android-only)
   Queries Android's `MediaStore` content provider for audio files in configured scan folders. Differential sync against the Isar database — only new/modified files trigger metadata parsing. Background metadata extraction handles CUE sheets and rip logs as a separate async pass. A `MediaStoreObserverService` monitors content changes and triggers live rescans.

2. **Rust `TwoPhaseScanner` + `EventDrivenScanner`** (legacy fallback)
   Used when `MediaStore` querying is unavailable or for direct filesystem access.

### Tier 1 — MediaStore Scanner (`LibraryScannerService`)

- `queryMediaStoreAudio()` — fetches audio files with path, size, last-modified, and `MediaStore` URI
- `queryMediaStoreNonAudio()` — fetches non-audio files (CUE, log, etc.) for sidecar metadata
- `queryMediaStoreDeletions()` — detects files removed since last scan
- Differential sync: compares `MediaStore` snapshot against Isar database; only `NEW`/`MODIFIED` entries proceed to metadata extraction
- Background pass: `_enrichMediaStoreSidecarsInBackground()` parses CUE sheets and rip logs

### Tier 2 — Rust File Scanner (Legacy)

The Rust scanner is split into three layers:

1. `TwoPhaseScanner`
   Performs a full filesystem walk, reads only `path`, `size`, and `last_modified_ms`, then diffs that snapshot against the shared file database.

2. `EventDrivenScanner`
   Uses OS-native watcher backends through `notify`:
   - Linux: `inotify`
   - macOS: `FSEvents` / `kqueue` fallback
   - Windows: `ReadDirectoryChangesW`

   It coalesces live events into batch updates so the database lock is taken once per flush instead of once per file.

3. `HybridScanner`
   Runs the bootstrap scan first, seeds the database, starts the watcher, and exposes a manual rescan path for recovery.

### Data Model

```text
FileFingerprint
  path: String
  size: u64
  last_modified_ms: i64
```

The fingerprint intentionally excludes expensive tag parsing. Metadata extraction can happen later, only for files classified as `NEW` or `MODIFIED`.

### Flow (MediaStore path)

```text
                         +-----------------------+
                         |   Isar SongEntity DB  |
                         +----------+------------+
                                    ^
                                    |
                     diff/batch upsert/deletes
                                    |
+------------------+       +--------+--------+       +--------------------------+
| MediaStore Query | ----> | Diff Engine     | <---- | MediaStoreObserverService|
| (audio + non-aud)|       | (snapshot vs DB)|       | (ContentObserver)        |
+------------------+       +--------+--------+       +--------------------------+
                                    |
                          +---------+---------+
                          | Metadata Parser   |
                          | (lofty, sidecars) |
                          +-------------------+
```

### Flow (Rust filesystem path)

```text
                 +----------------------+
                 | SharedFileDatabase   |
                 | path -> fingerprint  |
                 +----------+-----------+
                            ^
                            |
     bootstrap              | batch upserts/deletes
                            |
+-----------------+   diff   |   +----------------------+
| TwoPhaseScanner +----------+---+ EventDrivenScanner   |
| WalkDir + rayon |              | notify watcher       |
| stat only       |              | event coalescing     |
+--------+--------+              +----------+-----------+
         |                                  |
         | manual rescan                    | live create/modify/delete
         +----------------------------------+
```

## Complexity

- MediaStore query: `O(a + n)` where `a` = audio files, `n` = non-audio files.
  Android's `MediaStore` handles the indexed filesystem traversal internally — typically orders of magnitude faster than a full filesystem walk.
- Rust bootstrap scan: `O(n)` filesystem walk and stat collection.
- Diffing: `O(n)` with hash map lookups against the in-memory snapshot.
- Live updates: `O(k)` for `k` changed files/events.

## Expected Behavior

- MediaStore path (60 GB / ~1,300 tracks): **~328 ms total** — dominated by the `MediaStore` query itself (~180 ms), not I/O.
- Rust path (1k–10k files): Bootstrap under a second on SSD.
- Rust path (10k–100k files): Bootstrap grows linearly; unchanged files skip metadata parsing.
- Live watcher phase: Cost proportional to actual churn; effectively zero when idle.

## Trade-offs

- MediaStore query
  - Leverages Android's indexed file metadata — no full traversal needed.
  - Near-real-time via content observer, no polling overhead.
  - Android-only; cannot work on direct file URIs.

- Polling/filesystem bootstarp scan
  - Simple and deterministic.
  - Reliable for initial state.
  - Wasteful if repeated frequently because every pass touches the whole tree.

- Event-driven watcher
  - Scales with actual change volume.
  - Near-real-time updates.
  - Needs overflow/recovery handling, which is why the hybrid design keeps a manual rescan path.
