# AVDE v0.13.0 — final design and validation report

Frozen build: **`0.13.3+1a88d09c69d0`**. Every result below states the build and environment it was obtained on; raw outputs are in `docs/evidence/` (see its README).
Environment for all automated results: GNU Octave 8.4, headless Psychtoolbox
simulator (`tests/mock_ptb`, virtual clock that includes the task's real
computation and disk time but not GPU/driver time), synthetic CFD-like folder
(149 identities with HC and A; `tests/tools/make_synthetic_cfd.py`). No result
here was obtained in MATLAB, with real Psychtoolbox, the real CFD folder or a
real display.

## 1. Design-count table (every participant; asserted by `avde_validate_plan`)
| Horizon | Information | PP | NN | PN | Total |
|---|---|---|---|---|---|
| H1 | Equal [2 2] only | 16 | 16 | 16 | 48 |
| H6 | Unequal [3 1] only | 16 | 16 | 32 | 64 |
| Total | | 32 | 32 | 48 | 112 |

* H1-PN: Positive option = High in 8, Negative option = High in 8.
* H6-PP and H6-NN: less-observed option High 8 / Low 8.
* Single gap: Low mean 18, High mean 22, SD 8 (integers, truncated to [1, 50]).

## 2. H6-PN crosstab (reward level and valence of the LESS-observed option)
| | High | Low |
|---|---|---|
| **Negative** | 8 | 8 |
| **Positive** | 8 | 8 |

Therefore Positive less/more-observed 16/16, Negative 16/16, High less/more-observed 16/16.
Verified in 100/100 seeds and independently (Python) on the exported reference plan.

## 3. Presentation counterbalancing (exact within every 8-game cell)
Full 2×2×2 of {A/B label of High} × {High side} × {option previewed first}; H1
forced orders: first/last sample High/Low 2/2/2/2 and all six 2:2 orders; H6: the
single less-observed sample in each position 1–4 twice; PN Positive side 4/4;
H6 less-observed side 4/4. Global: High A/B 56/56, High left/right 56/56,
more-informed A/B 32/32. These cell-level and global balances are **invariants**
(asserted by the validator for every plan).

## 4. Sections and breaks
7 sections × 16 games; breaks after 16, 32, 48, 64, 80, 96 (participant-controlled,
logged). Each of the 14 cells contributes one game to every section plus one extra;
H1 games per section = 7,7,7,7,7,7,6 (order random per participant); whole-sequence
run limits: ≤ 5 same horizon, ≤ 4 same valence condition (asserted). Within-section
High side, A/B label and first-previewed option are **optimized toward 8/8** by a
hill-climb; the validator only **guarantees** High side within 8 ± 2 per section.
Exact 8/8 is a target achieved in tested seeds, not a universal invariant.
Reference participant (TEST_REFERENCE), games per section by horizon × valence:

| Section | H1 NN | H1 PN | H1 PP | H6 NN | H6 PN | H6 PP |
|---|---|---|---|---|---|---|
| 1 | 2 | 3 | 2 | 2 | 5 | 2 |
| 2 | 2 | 2 | 2 | 3 | 5 | 2 |
| 3 | 2 | 2 | 3 | 2 | 4 | 3 |
| 4 | 2 | 2 | 3 | 3 | 4 | 2 |
| 5 | 2 | 3 | 2 | 2 | 5 | 2 |
| 6 | 3 | 2 | 2 | 2 | 4 | 3 |
| 7 | 3 | 2 | 2 | 2 | 5 | 2 |

(H6-PN is 32 games, so 4–5 per section: exact equality across 7 sections is
impossible; each of its four cells appears in every section.)

## 5. Multi-seed validation (`docs/evidence/multiseed.csv`)
Build **0.13.3+d455ed452431** (between it and the frozen build only `avde_config.m`
gained two timing fields and `avde_collect_choice.m` / `avde_run_game.m` changed;
none of these is used by the plan, reward or stimulus functions this test exercises).
Every seed passed the full plan validator, the reward audit and the face-schedule
check (any violation aborts the test; missing practice coverage now also aborts).
| Check | Result |
|---|---|
| distinct plans | 100 / 100 |
| H6-PN 8/8/8/8 | 100 / 100 |
| practice cycle 1 covers all six horizon × valence cells | 100 / 100 |
| max run of same horizon (whole sequence) | 5 (limit 5) |
| planned image / identity reuse lag | ≥ 3 / ≥ 3 games (reuse at games g and g+3 allowed) |
| displayed forced gap | 4.0000 in every game |
| max reward-generation attempts per game | 617 (limit 20 000) |
| core face images per participant | 133 (66/67 per valence; race × gender strata differ by ≤ 1) |

**Face-by-condition association — weak evidence only.** Nominal χ² tests of
identity × High/Low and identity × less/more-observed gave p < .05 in 5% and 4% of
seeds. These tables count all *reserved* outcome images (not only displayed ones),
are very sparse (in the reference H6 table most expected cells are < 5), and the
constrained assignment is not an unconstrained random process, so the χ²
approximation is not calibrated here. The structural argument is stronger: the
face-assignment code selects images using only valence, within-game uniqueness,
reuse lags and usage counts; it never reads reward level or information role.
Realized exposure depends on participants' choices and cannot be balanced in advance.

## 6. Reward gap (three separate quantities; `tools/independent_reward_gap_check.py`)
| Quantity | Value |
|---|---|
| Latent gap (generating means) | 4 |
| Displayed forced-sample gap | exactly 4.000 (all 112 games; all 100 seeds) |
| Expected free-choice gap after truncation to [1,50] and rounding | **3.757** (Low 18.338, High 22.095; exact integration; Monte Carlo n = 400 000: 3.756) |
The realized template means across seeds (Low 18.26, High 22.10) also contain the
forced samples, which are conditioned on the exact gap.

## 7. Interruption / recovery (build 0.13.3+1a88d09c69d0)
**Injected faults — 15 / 15 pass** (`docs/evidence/crash_resume.csv`). These are
exceptions raised at a screen flip, a keyboard poll or a named persistence
boundary — not operating-system process kills. Scenarios: none; practice; games 5,
40, 17, 96; breaks 1 and 6; games 111 + 112 (two resumes); comprehension failure;
and five persistence-boundary faults: just **before** and just **after** the resume
checkpoint write (the audit's replay window), after a journal commit, after the
live start marker, and after the pre-break checkpoint. Checks per scenario: 112
slots; exactly the interrupted game(s) aborted (exposed games never replayed);
events belong to their game and are labelled core / practice correctly; plan and
pre-generated faces unchanged; 6 breaks; resume records; recovery files removed.

**Real process kills — 4 / 4 sessions pass, 7 kills in total** (`docs/evidence/process_kill.csv`, `tests/tools/process_kill_test.py`):
SIGKILL of the Octave process at random wall-clock times (5–75 s after each start,
up to 4 kills per session, 4 sessions; two sessions needed `avde_reexport` because a kill landed during CSV export; aborted games 87, 38, 78, 32 and 42 were each exactly the game live at a kill), including during MAT writes, renames,
deletes, resume reconciliation and CSV export; restart with the same ID after each
kill. Kills that landed after the final MAT but before export finished were
completed with the documented `avde_reexport` procedure. Checked: 112 slots; every
game whose live marker existed without a journal entry at kill time is aborted;
no more aborted slots than kills; one reset and one end per completed game; no
events for aborted games; core labels; no recovery files left.

## 8. Unit / negative tests (`docs/evidence/unit_tests.csv`, build 0.13.3+1a88d09c69d0) — 30 / 30 pass
SHA-256 vectors; image downscaling; layout at 5 resolutions; practice structure;
plan reproducibility; validator rejects the v0.12 H6-PN confound; mode/ID rules;
participant mode cannot start without a verified manifest and real Psychtoolbox;
missing journal / orphan journals refused; stale marker cleared; declined resume;
seven scripted keyboard edge cases (cross-poll 6 ms L+R rejected, both orders;
press 0.5 ms before / after the deadline; anticipatory press; held key at onset;
15 ms apart accepted); practice labels; foreign live marker refused; face bank
< 112 paired identities → explicit error; missing validation CSV → error;
simulator refused in participant/timing modes; `avde_reexport` idempotent and
every CSV carries `dataStatus`.

## 9. Timing (simulator reference session, build 0.13.3+1a88d09c69d0)
`docs/evidence/reference/timing_report.txt` and `…_timing_report.png`:
* inter-game: end → first face 2.000 s in all 105 in-section transitions, slope 0 s/game, 0 late; minimum preparation slack ≈ 1.47 s of 1.5 s;
* within-game: 3 639 flips, 0 missed frames; onset error |max| ≤ ½ frame for every event type;
* response → outcome: median 0.0332 s (2 frames at 60 Hz), max 0.0417 s;
* timeout feedback: scheduled at deadline + 50 ms (v0.13.3 drains the key queue 30 ms after the deadline; an earlier v0.13.3 build scheduled it at the deadline and was 1–4 frames late — found by the new within-game QC and fixed).
Simulator timing excludes GPU/driver time; it demonstrates that the task's own
computation and disk I/O fit the schedule, not that the lab display will.

| File | Size |
|---|---|
| per-game journal | ≈ 4.6–6.5 KB, no growth with game number |
| checkpoint near the end | ≈ 0.40–0.47 MB (written only at breaks/resume) |
| final `_complete.mat` | ≈ 0.53 MB |
| all CSVs | ≈ 1.9 MB |

## 10. Not verified here
* Real display/GPU timing and real keyboard hardware: run `START_AVDE_TIMING_SELFTEST` (timingtest mode, sync tests enforced) **and** a human keyboard rehearsal, then `tools/timing_report.py`.
* Power loss / disk-full conditions (process kills were tested; OS/filesystem failures were not).
* The optional local-validation CSV path (MATLAB `readtable`), not used in the pilot.
* MATLAB itself: all automated tests ran in Octave (the 0.13.0 CFD parser failed in MATLAB for exactly this reason); the code avoids Octave-/MATLAB-specific
  features where possible (no `datetime`, `string`, `writetable` in the task path),
  but a first development run in MATLAB on the lab PC is required.
