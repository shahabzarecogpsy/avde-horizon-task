# AVDE final pilot — v0.13.3

Affective Valence and Directed Exploration (modified Horizon Task), simplified
final pilot: **112 games in 7 sections of 16**, single reward gap (4).
MATLAB + Psychtoolbox-3; Chicago Face Database (CFD) images stay local.

## Repository notes
* Face images (Chicago Face Database) are **not** included and must not be committed; obtain the CFD under its own licence and point the task to it at runtime.
* Participant data (`data/`) are git-ignored and must never be committed.
* `.gitattributes` disables line-ending conversion: every file must stay byte-identical to `SHA256SUMS.txt`, which participant mode verifies. After cloning, participant mode must start without a manifest error; if it reports one, check your Git line-ending settings.
* After editing any file, regenerate `SHA256SUMS.txt` (see `docs/ARCHITECTURE.md`, section 6); edits to launchers, config, `src/` or `assets/` also change the build ID automatically.

## Run modes
| Purpose | Launcher | Mode | Sync tests | Data label |
|---|---|---|---|---|
| Real participant | `START_AVDE_PARTICIPANT` | participant | **enforced** | `PARTICIPANT` |
| Development / rehearsal (ID `TEST…`) | `START_AVDE_DEVELOPMENT` | development | skipped | `DEVELOPMENT_NOT_SCIENTIFICALLY_VALID` |
| Unattended display workload test (ID `TEST_TIMING…`) | `START_AVDE_TIMING_SELFTEST` | timingtest | **enforced** | `TIMING_TEST_AUTOPILOT_NOT_PARTICIPANT_DATA` |

Participant and timing-test modes also verify `SHA256SUMS.txt` and refuse the
test simulator (real Psychtoolbox required). The timing test generates responses
automatically; it does **not** replace a human keyboard rehearsal.
After a timing test: `python tools/timing_report.py data/<ID>_games.csv data/<ID>_events.csv`.

If a session is interrupted, start it again with the same ID and answer `Y`.
If a session finished but its CSVs are missing: `avde_reexport('data/<ID>_..._complete.mat')`.
Optional: `AVDE_DATA_ROOT` moves the data folder (recorded in `_meta.csv`).

## Outputs (`data/`)
`<ID>_<protocol>_complete.mat` (authoritative) and CSVs `_events`, `_games`
(112 slots incl. aborted), `_plan`, `_breaks`, `_resume_log`, `_practice_events`,
`_practice_games`, `_comprehension`, `_meta`. Every CSV row carries
`participantID`, `buildID`, `runMode`, `dataStatus`.

## Documentation
`docs/CHANGELOG_v0.13.0.md` (all versions), `docs/DESIGN_AND_VALIDATION.md`,
`docs/ARCHITECTURE.md`, `docs/SCIENTIFIC_LIMITATIONS.md`,
`docs/PARTICIPANT_TEXT_FA.md` (transcript of every participant screen),
`docs/evidence/` (test results, each stamped with build and environment).

## Tests — run ONLY in a disposable copy of this folder
The tests never touch `data/` (they use isolated temp folders), but they add
simulator paths and generate files; keep the deployed participant folder pristine.
```
python tests/tools/make_synthetic_cfd.py /tmp/synthcfd
octave --eval "cd tests; run_all_tests_octave('/tmp/synthcfd', '/tmp/avde_results', 100)"
python tests/tools/process_kill_test.py <copy_of_package> /tmp/synthcfd 3 4 /tmp/avde_results/process_kill.csv
```
`run_all_tests_octave` raises an error if any check fails.
