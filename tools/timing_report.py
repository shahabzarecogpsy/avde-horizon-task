"""Timing acceptance report for one session (real display or simulator).
Usage: python tools/timing_report.py data/<ID>_games.csv data/<ID>_events.csv [out.png]
Reports inter-game timing (vs game number), within-game onset errors by event
type, missed frames, response->outcome delay, and prints PASS/REVIEW flags.
Suggested acceptance (edit to your lab's criteria): no upward trend in inter-game
interval; <= 1% transitions late (> 2 frames); missed frames <= 0.5% of flips;
response->outcome median within one frame of 2 frames (33 ms at 60 Hz)."""
import sys, csv, statistics as st
import matplotlib; matplotlib.use('Agg'); import matplotlib.pyplot as plt
gf, ef = sys.argv[1], sys.argv[2]; out = sys.argv[3] if len(sys.argv) > 3 else gf.replace('_games.csv', '_timing_report.png')
G = [r for r in csv.DictReader(open(gf, encoding='utf-8')) if r['slotStatus'] == 'completed']
E = list(csv.DictReader(open(ef, encoding='utf-8')))
f = lambda x: float(x) if x not in ('', 'NaN') else float('nan')
tr = [(int(r['game']), f(r['interGameEndToFirstFaceSeconds']), f(r['interGamePrepSlackSeconds']), r['interGameLate'] in ('1', 'true', 'True')) for r in G if r['interGameEndToFirstFaceSeconds'] not in ('', 'NaN')]
g = [t[0] for t in tr]; ig = [t[1] for t in tr]; sl = [t[2] for t in tr]; late = sum(t[3] for t in tr)
mx = st.mean(g); my = st.mean(ig); slope = sum((a-mx)*(b-my) for a, b in zip(g, ig)) / sum((a-mx)**2 for a in g)
flips = [r for r in E if r['onsetError'] not in ('', 'NaN')]
missed = sum(r['missedFrame'] in ('1', 'true', 'True') for r in flips)
bytype = {}
for r in flips: bytype.setdefault(r['eventType'], []).append(f(r['onsetError']))
resp = {(r['game'], r['freeTrial']): f(r['responseTime']) for r in E if r['eventType'] == 'free_choice'}
delay = [f(r['actualOnset']) - resp[(r['game'], r['freeTrial'])] for r in E if r['eventType'] == 'joint_outcome' and (r['game'], r['freeTrial']) in resp]
print('inter-game end->first face: n=%d mean %.4f max %.4f slope %.2e s/game; late %d (%.1f%%); min slack %.4f s' % (len(ig), my, max(ig), slope, late, 100*late/len(ig), min(sl)))
print('flips %d, missed frames %d (%.2f%%)' % (len(flips), missed, 100*missed/len(flips)))
for k, v in sorted(bytype.items()):
    v = sorted(v); print('  %-18s n=%4d onsetError median %+.4f  p99 %+.4f  max %+.4f s' % (k, len(v), st.median(v), v[int(0.99*(len(v)-1))], v[-1]))
print('response->outcome delay: median %.4f  max %.4f s (n=%d)' % (st.median(delay), max(delay), len(delay)))
flags = []
if slope > 1e-4: flags.append('inter-game trend')
if late > 0.01*len(ig): flags.append('late transitions > 1%')
if missed > 0.005*len(flips): flags.append('missed frames > 0.5%')
print('RESULT:', 'PASS' if not flags else 'REVIEW: ' + ', '.join(flags))
fig, ax = plt.subplots(3, 1, figsize=(10, 9))
ax[0].plot(g, ig, 'o', ms=3); ax[0].axhline(2.0, ls='--', c='k'); ax[0].set_ylabel('end->first face (s)'); ax[0].set_title('%s  slope %.2e s/game' % (gf.split('/')[-1], slope), fontsize=9)
ax[1].plot(g, sl, 'o', ms=3); ax[1].axhline(0, c='r'); ax[1].set_ylabel('prep slack (s)'); ax[1].set_xlabel('game')
ax[2].boxplot([bytype[k] for k in sorted(bytype)], tick_labels=sorted(bytype), showfliers=True); ax[2].set_ylabel('onset error (s)'); ax[2].tick_params(axis='x', rotation=45, labelsize=7)
plt.tight_layout(); plt.savefig(out, dpi=120); print('plot ->', out)
