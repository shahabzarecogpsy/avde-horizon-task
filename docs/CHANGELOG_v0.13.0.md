# v0.13.3 (build 0.13.3+1a88d09c69d0) — fixes from the independent audit of v0.13.2
* **Timeout feedback timing (found by the new within-game QC during v0.13.3 testing):** because the key queue is now drained 30 ms after the 4-s deadline, feedback after a timeout is scheduled at deadline + 50 ms (`cfg.timing.timeoutFeedbackDelay`; drain `cfg.input.postDeadlineDrain`). An intermediate v0.13.3 build scheduled it at the deadline and was 1–4 frames late.
All audit findings were checked against the code and confirmed; each is fixed below.

**Recovery**
* Durability order: on resume the reconciled checkpoint (incl. any aborted slot) is saved **before** the live marker is deleted (v0.13.0–0.13.2 deleted it first: an interruption in that window could replay an exposed game).
* Live markers now carry participant ID, behaviour hash and plan ID; a foreign marker is refused (`AVDE:LiveMarkerIdentity`).
* Orphaned `*.tmp.mat` files from a kill during an atomic save are removed at completion.
* New `avde_reexport(finalMat)`: rebuilds CSVs from the authoritative final MAT and removes leftover recovery files (the task refuses to re-run a completed ID and now points to this tool).

**Tests could delete participant data (fixed)**
* Tests no longer touch the package `data/` folder: every run uses an isolated temp root (`AVDE_DATA_ROOT`), cleanup refuses any other folder, and the MATLAB path/environment/simulator state are restored afterwards.
* Test results are written outside the release (`run_all_tests_octave(cfdRoot, outDir, nSeeds)` refuses an outDir inside the package), so running tests cannot change manifest-covered files. Shipped evidence lives in `docs/evidence/`.
* The aggregate runner raises an error if any check fails; the multi-seed test now fails on missing practice coverage.

**Run modes / timing test**
* New `timingtest` mode (IDs `TEST_TIMING…`): Psychtoolbox sync tests **enforced**, manifest verified, automatic responses. The timing self-test no longer runs in development mode (which skips sync tests), and the `AVDE_AUTOPILOT` environment variable was removed (autopilot is set only by the mode and reset on exit; the launcher is now a function).
* Participant and timing-test modes refuse the test simulator (`AVDE:MockPsychtoolbox`).
* `avde_session_qc` and new `tools/timing_report.py` report within-game onset errors by event type, missed frames and response→outcome delay, not only inter-game timing (replaces `plot_intergame_timing.py`).

**Keyboard** (`avde_collect_choice` rewritten)
* Adjudication by hardware timestamps: presses valid only if onset ≤ t ≤ deadline; a 30 ms post-deadline drain prevents losing a just-in-time press; post-deadline presses are ignored.
* The 10 ms near-simultaneous rule now holds across polls (candidate accepted only after polling passes t + 10 ms).
* `keyHeldAtOnset` sampled right after the onset flip; a same-key press after an anticipatory press in one poll is recovered via `lastPress`.

**Data labels**
* Practice joint-outcome events were labelled `attemptType = core` (merge overwrote the label). Identity/design fields are now protected during merges, and export asserts that practice events are `practice` and core events `core`.
* Every exported CSV row now carries `participantID`, `buildID`, `runMode`, `dataStatus`.

**Stimuli / validation**
* Explicit error if fewer than 112 identities have both HC and A images (previously a small bank could loop forever); the practice-reservation loop fails if it makes no progress.
* A set-but-missing `AVDE_LOCAL_VALIDATION_CSV` is now an error (was silently ignored).
* Removed the unimplemented `maxIdentityCovariateSMD` setting and its claim; allocation balances race × gender only. All item-level covariates are kept in the saved pools.

**Other**
* `cfg.practice.nGames` corrected to 6 and asserted by the practice builder.
* Instruction page 3: the Latin "37 / 112" example rendered in reversed order inside Persian text; replaced by a wording without numbers. `docs/PARTICIPANT_TEXT_FA.md` is now a complete transcript of every screen.
* Documentation corrected: evidence provenance per build; section balance described as a target (8/8) with a guaranteed bound (±2); face-association p-values described as nominal and weak evidence (sparse tables; constrained assignment); crash "hard kills" described as injected exceptions, complemented by real SIGKILL tests.

# v0.13.2 (build 0.13.2+3392939ab732)
* **Removed the "1 / 6 انتخاب آزاد" label** from the top of the game screen (requested): the number of free choices is conveyed by the number of history rows under each source (5 rows = 1 free choice, 10 rows = 6), which are drawn from game onset. This restores the presentation of the earlier pilots. The progress counter is unchanged.
* Code: `src/avde_draw_game_header.m` (label drawing removed), `src/avde_setup_display.m` (label textures no longer loaded), `src/avde_check_dependencies.m`, `src/avde_build_layout.m` (label area removed from the header check), comment in `src/avde_run_game.m`; `assets/instructions_fa/badge_h1.png`, `badge_h6.png` deleted.
* Participant text updated and re-rendered (`tools/render_instructions_fa.py`): instructions page 3 (bullet on free choices now explains 5 vs 10 rows), guided practice screens 1 and 2, and comprehension question 4 (now asks about 10 rows; answers and key L R L R L unchanged).
* Verification on 0.13.2: 17/17 unit tests; clean 112-game reference session (design audit PASS; end → first face 2.000 s, no trend); crash/resume spot-check (two consecutive crashes; comprehension failure) passed; manifest regenerated and verified by the task's checker. Plan, reward, stimulus and recovery code unchanged, so the 100-seed and 10-scenario results still apply.

# v0.13.1 hotfix (build 0.13.1+a5f8879b70f2)
* **Bug (MATLAB only):** `avde_build_cfd_manifest` used a regular expression with nested groups. Octave returns nested groups as tokens, MATLAB does not, so the first MATLAB run stopped with "Index exceeds the number of array elements" while scanning the CFD folder. The pattern now has five non-nested groups (race, gender, model, photo, expression), which both interpreters return identically.
* Verification: on the synthetic CFD folder the new parser returns a manifest identical to the old one (298 rows; path, file, hash, expression, model, identity, valence, race, gender all equal); 17/17 unit tests; clean 112-game reference session; crash/resume spot-check (two consecutive crashes; crash in game 5) passed. No other nested-group expressions exist in the task code. Plan, reward, face-assignment and recovery code are unchanged from 0.13.0, so the 100-seed and 10-scenario results of 0.13.0 still apply.
* Version label changed to 0.13.1 (build ID changes automatically).

# Changelog — v0.13.0 (final pilot) relative to v0.12.1 (TIMINGFIX_R2)

## Scientific design (as specified; nothing else changed)
* 112 games (was 96): H1 48 = PP/NN/PN 16/16/16, Equal [2 2] only; H6 64 = PP/NN/PN 16/16/32, Unequal [3 1] only.
* New plan builder: the design is written as 14 literal 8-game cells ("atoms"); no factor is derived from another factor or a shared parity term. **The v0.12 defect (Positive always more-observed in H6-PN; Build A: High always less-observed) is structurally impossible and is rejected by the validator (tested).**
* H6-PN: less-observed valence × reward level = 8/8/8/8 in every plan.
* Single latent gap 4 unchanged (Low 18, High 22, SD 8, integer, truncated to [1,50]); displayed forced gap exactly 4 unchanged.

## Counterbalancing added (presentation; exact within every 8-game cell)
* Which internal label (A/B) is High — previously A was always Low.
* High side, and hence Positive side (PN) and less-observed side (H6).
* Preview order X Y Y X with the first-previewed option balanced — previously always the left source first.
* Forced-sample order: H1 first/last sample High/Low balanced and all six 2:2 orders used; H6 position of the single less-observed sample balanced (2 per position).
* Sections: every cell contributes one game to every section (+1 extra); H1 per section 7,7,7,7,7,7,6; side/label/preview balance optimized within each section (residual cost 0 in tested seeds); run-length limits (≤ 5 same horizon, ≤ 4 same valence condition).
* Face pools: core identities are allocated to Positive/Negative within race × gender strata (difference ≤ 1 per stratum).

## Sections, breaks, progress, instructions
* 7 sections × 16 games; participant-controlled breaks after games 16, 32, 48, 64, 80, 96; onset, key-press time, end and duration recorded.
* Progress counter "g / 112" (Latin digits, higher contrast) and a pre-rendered "1 / 6 انتخاب آزاد" badge in a header band that the layout validator proves cannot overlap faces, decks, cues or rewards; visible throughout every game from game onset.
* All Persian screens rewritten and re-rendered (tools/render_instructions_fa.py; text in docs/PARTICIPANT_TEXT_FA.md): states that only free-choice points count; neutral about faces; removes the misleading "no predetermined correct answer"; fixes the title/bullet overlap of v0.12 page 1.
* Comprehension: 5 rule questions (variability, XX, which points count, number of free choices, deadline); answer sides L R L R L.
* Practice: 6 games (one per horizon × valence condition; first two guided), repeat cycle 3 games, max 3 cycles; single gap 4; all non-fixed factors random per game.

## Timing and persistence
* Inter-game: game_end → game_reset 1.5 s, → first face 2.0 s (was 3.0 s end→face).
* Faces decoded once at startup into RAM (down-scaled); per-game texture creation has no disk access (v0.12.1: 0.23–0.69 s of JPEG decoding per transition).
* Removed ~20 in-game live-state writes per game (one sat between response and outcome); now ≤ 7 tiny writes, only after long-duration flips.
* Checkpoints only at startup, after practice and at breaks; one bounded journal per game.
* Choice screen no longer blocks while a key is held.

## Recovery
* Approved policy: an interrupted game is closed as `aborted_interrupted` and never replayed or replaced; all untouched games keep their original plan, faces and rewards. Journal gaps, foreign/other-build entries and orphan files are refused.

## Run modes and versioning
* Two modes: `participant` (sync tests enforced, no override; manifest verified) and `development` (TEST IDs; labelled not scientifically valid). An unattended autopilot exists only in development mode (`AVDE_AUTOPILOT=1`) for real-display timing tests.
* Automatic behaviour hash / build ID; plan hash; all stored in every file.

## Files removed and why
| Removed | Reason |
|---|---|
| `src/avde_build_probe_plan.m`, `avde_run_probe_game.m`, `avde_run_probes.m`, `assets/ratings_fa/probe_*.png` | diagnostic probes were disabled and are not part of the design |
| `src/avde_collect_state_ratings.m`, `avde_collect_slider_rating.m`, `assets/ratings_fa/state_*.png` | state ratings off by approved decision; code referenced probe config and was untested |
| `src/avde_make_replacement_plan.m`, `avde_assign_replacement_stimuli.m`, replacement identity reserve | replacement games replaced by the approved abort-and-continue policy |
| `src/avde_draw_mosaic.m` | never called in any build (call was commented out); sources are identified by side |
| `src/avde_draw_horizon.m` | empty function (horizon shown by rows and the new badge) |
| `src/avde_preview_phase.m`, `avde_forced_phase.m`, `avde_show_end_screen.m`, `avde_tex_from_image.m`, `avde_run_instructions.m`, `avde_init_session.m` | merged into `avde_run_game.m` / `run_AVDE.m` / `avde_show_instructions.m` |
| `src/avde_live_game_*.m`, `avde_safe_save.m`, `avde_reconcile_live_attempt.m` | replaced by `avde_live_save/_load`, `avde_atomic_save`, `avde_game_commit_*` |
| `run_AVDE_palette_check.m`, `run_AVDE_visual_demo.m` | referenced the removed 96-game/probe structures |
| old instruction PNGs (`01_pictures`, `02_points`, `03_choice`, `practice_tip`, `midbreak`) | replaced by re-rendered screens |
| v0.11/v0.12 docs, `README_*`, `REFACTOR_STATUS.md` | described superseded designs; replaced by v0.13.0 docs |
| old `tests/*.m`, `tools/*.py` | written for the 96-game/replacement design; replaced by the new Octave suite and tools |

## Kept from v0.12.1 (reviewed, unchanged in behaviour)
Frame-locked scheduling, display/keyboard setup, layout geometry (plus header band), history table, response cues, joint outcome, truncated-normal sampler, exact-forced-gap reward logic, lag-constrained face assignment, optional local validation path.
