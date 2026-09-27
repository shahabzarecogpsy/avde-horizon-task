# AVDE v0.13.0 — architecture: saving, recovery, timing, data, versioning

## 1. What is generated before the first screen (and never regenerated)
All randomness is drawn once, from isolated seeded streams, before the display opens:
plan (`avde_build_plan`, validated by `avde_validate_plan`), rewards
(`avde_generate_reward_templates`, audited), face pools (`avde_partition_manifest`)
and the complete face schedule (`avde_assign_stimuli_to_plan`, re-checked by
`avde_validate_stimulus_schedule`). Nothing random happens during a game, so no
RNG state is needed for recovery. All four objects are stored in the session
checkpoint written before instructions; a resumed session uses these stored
objects verbatim (plan, rewards, faces), never re-generated ones.

## 2. Save / recovery architecture
| File (data/…) | Written when | Size (measured, simulator) | Purpose |
|---|---|---|---|
| `checkpoints/<ID>_<protocol>_checkpoint.mat` | startup, after practice, at the start and end of each of the 6 breaks | ≈ 0.40–0.47 MB near the end (grows with completed games) | authoritative resume base |
| `live/<ID>_…_core_NNN_commit.mat` | once per completed core game, after its `game_end` flip | 4.6–6.5 KB, no growth | journal of completed games since the last checkpoint |
| `live/<ID>_…_live.mat` | at game start; after the 4th forced point; after each joint outcome | bounded (≤ one game) | marks an in-progress game and the last reached phase |
| `<ID>_…_complete.mat` + CSVs | end of session | — | final data |
| `<ID>_…_ERROR.mat` | on a caught MATLAB error | — | diagnostic snapshot (resume does not use it) |

Every write is atomic (temporary file + rename, MAT v7). The cumulative session is
**never** serialized between two consecutive games: the only inter-game write is
the bounded journal file. Large checkpoints happen only at breaks, which are
participant-paced and have no timing target.

**Resume algorithm** (`run_AVDE`): load checkpoint → refuse if it was written by
a different build (behaviour hash) or run mode → re-verify face-file hashes →
replay journal files strictly in order (a gap = error, never a silent skip; an
entry from another participant/build = error) → inspect the live marker, which
must carry this participant ID, behaviour hash and plan ID (otherwise error):
* marker for a game already journaled or already closed → stale;
* marker for the next game → that game was (possibly) exposed: its slot is closed
  as `aborted_interrupted` (last recorded phase and partial events kept in
  `abortedLogs`), it is **never replayed or replaced**, and the session continues
  with the next planned game (approved policy; fewer than 112 usable games possible);
* anything else → error.

**Durability order (v0.13.3):** the reconciled state (replayed journals + any
aborted slot) is written to the checkpoint **first**; the live marker is deleted
**only afterwards**. An interruption between the two leaves a marker for a slot
that is already closed, which the next resume treats as stale. An interruption
before the checkpoint write leaves the marker in place, so the next resume reaches
the same abort decision. (v0.13.0–0.13.2 deleted the marker first; an interruption
in that window could have replayed an exposed game.) This window is covered by
injected faults at both boundaries and by real SIGKILL tests (validation report).

Live-marker snapshots are written at game start and at phase boundaries only, so
the recorded `abortPhase` can lag actual exposure by up to one phase, and a crash
after the start marker but before the first visible frame is also classified as
aborted (conservative).

If the last completed game ends a section and its break was not recorded, the
break is shown first. Practice interrupted before completion restarts from its
beginning (practice is not analysed as core data). Journals/markers without a
checkpoint are refused (`AVDE:OrphanRecoveryFiles`). Declining a resume changes
nothing unless the operator types `RESTART`, which moves (never deletes) all
recovery files to `data/archive/` and records the prior exposure. Temporary
`*.tmp.mat` files left by a kill during an atomic save are never read and are
removed at completion. If the final MAT exists but CSV export did not finish,
`avde_reexport` rebuilds the CSVs from the final MAT and removes leftovers.

## 3. Inter-game timing path (normal operation, within a section)
```
game_end flip (blank)        t0
  ├─ journal commit (bounded .mat), delete live marker, write next live marker
  ├─ create ≤16 textures from the in-RAM image cache (no disk, no JPEG decoding)
  └─ wait (absolute target, no WaitSecs added)
game_reset flip              t0 + 1.500 s   (board with 5/10 history rows + progress counter)
first face preview flip      t0 + 2.000 s
```
Face images are decoded once at startup and down-scaled in RAM (integer box
filter to ≥ the largest on-screen face height). Pixels are never written to disk
or into data files. Within games, live-marker writes happen only right after a
flip that is followed by ≥ 0.8 s of display time, never between a key press and
its outcome. Timing targets are never carried across a break or a resume.
Logged per game: `interGameEndToResetSeconds`, `interGameEndToFirstFaceSeconds`,
`interGameTimingError`, `interGameLate` (> 2 frames), `interGamePrepSlackSeconds`,
`texturePrepSeconds`.

Within a game (all absolute, frame-locked): reset 0.5 s; 4 × (preview face 1.2 s +
ITI 0.5 s); 4 × (forced cue 0.3 s + forced point 0.8 s + ITI 0.5 s); free choice
(≤ 4.0 s) → outcome 2 frames after the response (points + face, 1.5 s) → ITI 0.5 s;
game_end. `onsetError` = actual − requested (half-frame early `when` ⇒ within ±½ frame
when no frame is missed).

## 4. Keyboard handling (`avde_collect_choice`, v0.13.3)
Presses are adjudicated by their KbQueue hardware timestamps, not by polling time.
Valid window: onset ≤ t ≤ onset + 4.000 s; after the deadline the queue is drained
for a further 30 ms (after a timeout the feedback screen is scheduled at deadline + 50 ms) so a press stamped just before the deadline is never lost, and
presses stamped after the deadline are ignored. Near-simultaneous presses of both
keys (≤ 10 ms apart) are rejected even when they arrive in different polls: a
candidate press is accepted only after polling has passed t + 10 ms (adds ≤ ~11 ms
before the outcome is scheduled; the outcome still appears 2 frames after the
press timestamp when possible). Presses before onset are logged (`anticipatoryPress`)
and ignored; if the same key is pressed again after onset within the same poll,
the later press (`lastPress`) is used. `keyHeldAtOnset` is sampled immediately after
the onset flip. Held keys never delay the screen. Other keys are counted
(`invalidKeyCount`); RT < 150 ms is flagged (`fastResponse`) but counts.
All seven rules are covered by scripted-press unit tests.

## 5. Data-field classification (final `session` structure)
| Class | Fields |
|---|---|
| 1. Required for analysis | (every CSV row also carries participantID, buildID, runMode, dataStatus) `plan` (112 rows: order, section, horizon, pair type, information, High/Low, more/less-observed, valences, sides, forced sequence, preview order), `gameSummaries` (112 slots incl. aborted), `gameLogs` (events: design copy, rewards, choices, RTs, timeouts, invalid/anticipatory/held keys, image IDs, onsets), `rewards`, `stimulusMap`, `pools` (file names, hashes, identity, valence, race, gender — no pixels), `practice`, `breakLog`, `config` |
| 2. Recovery / QC | `qc` (inter-game and within-game timing, missed frames, response→outcome delay, response-quality counts), `stage`, `lastCompletedCoreGame`, `resumeLog`, `abortedLogs`, `displayHistory`, `qc`, `lastError`, journal and live files |
| 3. Metadata | `meta` (IDs, version, protocol, release, buildID, behaviourHash, releaseManifestSha256, runMode, dataStatus, syncTestsSkipped, randomSeed, planID/planHash, stimulusMapID, times, resumeCount, restartArchive), `environment`, `planValidation`, `rewardAudit`, `stimulusValidation` |
| 4. Removed (redundant/obsolete) | probe logs/plans; replacement map/pool; cumulative `eventLog` array (now per-game cells); `layout` (reconstructible from config + display); `rngState` (no runtime randomness); `interruptionLog`/`resumeDisplay` (merged into `resumeLog`/`displayHistory`); source codes; per-event local-rating columns; redundant flip fields (`flipWhen`, `flipTimestamp`, `beamPosition`, `missedSeconds`) |

## 6. Versioning and reproducibility
* `cfg.version` (human), `cfg.protocolVersion`, `cfg.releaseID` (human labels).
* **`behaviourHash`** — computed at every start from every launcher, `run_AVDE.m`,
  `avde_config.m`, `src/**` and `assets/**`; `buildID = <version>+<first 12 hex>`.
  Any byte change in behaviour-relevant code or assets changes the build ID
  automatically; resume and journal replay refuse a different behaviour hash.
* Regenerating the manifest after an edit (MATLAB, from the package folder, with `data/` absent or empty):
  ```matlab
  root = pwd; addpath(fullfile(root,'src'));
  f = avde_list_files(root, {'data'}); f = f(~strcmp(f,'SHA256SUMS.txt'));
  fid = fopen(fullfile(root,'SHA256SUMS.txt'),'w');
  for k = 1:numel(f); fprintf(fid,'%s  %s\n', avde_sha256_file(fullfile(root,strrep(f{k},'/',filesep))), f{k}); end
  fclose(fid); avde_verify_release_manifest(root);
  ```
* `SHA256SUMS.txt` covers every release file (docs/tests/tools included) and is
  verified in participant mode; its own hash is stored as `releaseManifestSha256`.
* `planHash` (SHA-256 of a canonical serialization of the plan; `planID` = first 12 hex),
  `stimulusMapID`, `rewardTemplateID`s, `randomSeed` are stored in every file.

## 7. Stimulus bank and optional local face validation
The bank must contain **at least 112 identities that have BOTH an HC and an A
image** (16 practice + 48 per core valence); otherwise startup stops with
`AVDE:StimulusBankTooSmall`. Core identities are allocated to Positive/Negative
within race × gender strata only; **no covariate (attractiveness, age, rating)
matching is performed** (the unused v0.13.0 setting `maxIdentityCovariateSMD`
was removed). If `AVDE_LOCAL_VALIDATION_CSV` is set, the file must exist (else
`AVDE:ValidationCsvMissing`); it is applied (exclusions, ratings, race/gender) and
its hash stored, and all item-level covariates are kept in `session.pools`. This
path uses MATLAB `readtable` and is **not** exercised by the Octave test suite:
test it in MATLAB before relying on it.
