# Evidence files (read-only records; not used by the task)

| File | Produced by | Build | Environment |
|---|---|---|---|
| `unit_tests.csv` | `tests/test_unit.m` | 0.13.3+1a88d09c69d0 | GNU Octave 8.4, mock PTB, synthetic CFD |
| `crash_resume.csv` | `tests/test_crash_resume.m` (injected exceptions + persistence-boundary faults) | 0.13.3+1a88d09c69d0 | same |
| `process_kill.csv` | `tests/tools/process_kill_test.py` (real SIGKILL, seed 2028) | 0.13.3+1a88d09c69d0 | same |
| `multiseed.csv`, `multiseed_summary.txt` | `tests/test_multiseed.m`, 100 IDs | 0.13.3+d455ed452431 (plan/reward/stimulus code identical to 0.13.3+1a88d09c69d0) | same |
| `reference/` | one full simulated session `TEST_REFERENCE` + `tools/timing_report.py`, `tools/independent_design_audit.py`, `tools/independent_reward_gap_check.py` | 0.13.3+1a88d09c69d0 | same |

Earlier builds' evidence (0.13.0–0.13.2) is superseded and not shipped.
The behaviour hash covers launchers, config, `src/` and `assets/` only; adding
evidence files changes the release manifest (`SHA256SUMS.txt`) but not the
build ID. None of these results was obtained in MATLAB, with real Psychtoolbox,
the real CFD folder or real display hardware.
