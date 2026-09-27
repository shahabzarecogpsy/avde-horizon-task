"""Real process-termination test (SIGKILL at random wall-clock times).
Unlike the injected-exception scenarios, the OS kills the Octave process at an
arbitrary instruction, including in the middle of MAT writes, renames, deletes
and resume reconciliation. After each kill the task is restarted with the same
ID (resume = Y) until the session completes; then invariants are checked.
Usage: python tests/tools/process_kill_test.py <package_root> <cfd_root> <n_trials> <kills_per_trial> <out_csv>
Requires GNU Octave and SciPy. Uses an isolated data root under the system temp dir."""
import os, sys, time, random, signal, subprocess, tempfile, csv, glob, shutil
import scipy.io as sio
root, cfd, nTrials, nKills, out = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), sys.argv[5]
random.seed(int(os.environ.get('KILL_SEED', '2026')))
rows = []
for trial in range(1, nTrials + 1):
    pid = 'TEST_KILL%02d' % trial
    dataRoot = tempfile.mkdtemp(prefix='AVDE_test_data_kill_')
    env = dict(os.environ, AVDE_DATA_ROOT=dataRoot, AVDE_NONINTERACTIVE_ANSWER='y')
    code = ("addpath('%s/tests/mock_ptb'); addpath('%s/src'); addpath('%s'); mock_reset(struct()); run_AVDE('%s','%s','development');"
            % (root, root, root, pid, cfd))
    kills, expectAbort, attempts, finalizedByReexport = 0, set(), 0, False
    while True:
        attempts += 1
        p = subprocess.Popen(['octave-cli', '--no-gui', '-q', '--eval', code], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
        if kills < nKills:
            t = random.uniform(5, 75)
            try:
                p.wait(timeout=t); rc = p.returncode
            except subprocess.TimeoutExpired:
                os.kill(p.pid, signal.SIGKILL); p.wait(); kills += 1
                # classify what the kill interrupted, from durable files only
                live = glob.glob(os.path.join(dataRoot, 'live', '*_live.mat'))
                if live:
                    try:
                        g = int(sio.loadmat(live[0], squeeze_me=True, struct_as_record=False)['live'].game)
                        if not os.path.exists(os.path.join(dataRoot, 'live', '%s_AVDE-v0_13-FINALPILOT-112_core_%03d_commit.mat' % (pid, g))):
                            expectAbort.add(g)
                    except Exception:
                        pass  # a marker killed mid-write is unreadable -> tmp file only; final name never partial
                continue
        else:
            p.wait(); rc = p.returncode
        if rc != 0:
            err = p.stderr.read().decode(errors='replace')
            if 'Completed data already exist' in err:
                # Kill landed after the authoritative final MAT was written but before CSV
                # export/cleanup finished. Documented operator procedure: avde_reexport.
                fin = glob.glob(os.path.join(dataRoot, pid + '_*_complete.mat'))[0]
                r2 = subprocess.run(['octave-cli', '--no-gui', '-q', '--eval', "addpath('%s'); avde_reexport('%s');" % (root, fin)],
                                    env=env, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
                finalizedByReexport = True
                if r2.returncode != 0:
                    rows.append(dict(trial=trial, kills=kills, ok=0, detail='avde_reexport failed: ' + r2.stderr.decode(errors='replace')[-300:].replace('\n', ' ')))
                break
            rows.append(dict(trial=trial, kills=kills, ok=0, detail='task exited with error: ' + err[-400:].replace('\n', ' '))); break
        break
    if len(rows) >= trial:
        continue
    G = list(csv.DictReader(open(os.path.join(dataRoot, pid + '_games.csv'), encoding='utf-8')))
    E = list(csv.DictReader(open(os.path.join(dataRoot, pid + '_events.csv'), encoding='utf-8')))
    status = {int(r['game']): r['slotStatus'] for r in G}
    aborted = {g for g, s in status.items() if s.startswith('aborted')}
    completed = {g for g, s in status.items() if s == 'completed'}
    ev = {}
    for r in E: ev.setdefault(int(r['game']), []).append(r['eventType'])
    checks = {
        '112 slots': sorted(status) == list(range(1, 113)),
        'completed+aborted = 112': len(completed) + len(aborted) == 112,
        'every game live at a kill (uncommitted) is aborted, never replayed': expectAbort <= aborted,
        'aborted only where a kill occurred': len(aborted) <= kills,
        'each completed game: exactly one reset and one end': all(ev.get(g, []).count('game_reset') == 1 and ev[g].count('game_end') == 1 for g in completed),
        'no events for aborted games in core events': all(g not in ev for g in aborted),
        'all core events labelled core': all(r['attemptType'] == 'core' for r in E),
        'recovery files removed': not glob.glob(os.path.join(dataRoot, 'live', '*.mat')) and not glob.glob(os.path.join(dataRoot, 'checkpoints', '*.mat')),
    }
    ok = all(checks.values())
    rows.append(dict(trial=trial, kills=kills, ok=int(ok), detail='%saborted=%s expected>=%s; %s' % ('finalized by avde_reexport after kill during export; ' if finalizedByReexport else '', sorted(aborted), sorted(expectAbort), '; '.join(k for k, v in checks.items() if not v) or 'all checks passed')))
    shutil.rmtree(dataRoot, ignore_errors=True)
    print(rows[-1], flush=True)
with open(out, 'w', newline='') as fh:
    w = csv.DictWriter(fh, fieldnames=['trial', 'kills', 'ok', 'detail']); w.writeheader(); w.writerows(rows)
sys.exit(0 if all(r['ok'] for r in rows) else 1)
