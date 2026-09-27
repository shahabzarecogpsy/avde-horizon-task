"""Independent (Python) audit of an exported plan: data/<ID>_plan.csv.
Re-derives every design count from the exported rows (does not reuse task code)
and exits non-zero on any violation. Prints the deliverable tables."""
import sys, pandas as pd
p = pd.read_csv(sys.argv[1]); fails = []
def need(c, m):
    if not c: fails.append(m)
need(len(p) == 112 and list(p.game) == list(range(1, 113)), '112 games in order')
p['lessVal'] = p.apply(lambda r: r['option%sValence' % r.lessInformativeOption] if r.horizon == 6 else 'Equal', axis=1)
p['lessLev'] = p.apply(lambda r: r['option%sRewardLevel' % r.lessInformativeOption] if r.horizon == 6 else 'Equal', axis=1)
p['highVal'] = p.apply(lambda r: r['option%sValence' % r.highOption], axis=1)
p['highLeft'] = (p.apply(lambda r: r['option%sSide' % r.highOption], axis=1) == 'L')
print('== Design counts (horizon x valence condition)'); t = pd.crosstab(p.horizon, p.valenceCondition, margins=True); print(t)
need((t.loc[1, ['PP', 'NN', 'PN']] == [16, 16, 16]).all() and (t.loc[6, ['PP', 'NN', 'PN']] == [16, 16, 32]).all(), 'H1 16/16/16, H6 16/16/32')
need(set(p[p.horizon == 1].information) == {'Equal'} and set(p[p.horizon == 6].information) == {'Unequal'}, 'information by horizon')
need(((p.horizon == 1) & ((p.forcedCountA != 2) | (p.forcedCountB != 2))).sum() == 0, 'H1 [2 2]')
h6 = p[p.horizon == 6]; need((h6[['forcedCountA', 'forcedCountB']].apply(sorted, axis=1).apply(tuple) == (1, 3)).all(), 'H6 [3 1]')
print('\n== H1-PN: valence of the High option'); x = pd.crosstab(p[(p.horizon == 1) & (p.valenceCondition == 'PN')].highVal, 'n'); print(x); need((x.n == 8).all(), 'H1-PN 8/8')
for vc in ['PP', 'NN']:
    x = h6[h6.valenceCondition == vc].lessLev.value_counts(); print('\n== H6-%s less-observed reward level' % vc); print(x.to_string()); need(x.get('High', 0) == 8 and x.get('Low', 0) == 8, 'H6-%s 8/8' % vc)
pn = h6[h6.valenceCondition == 'PN']; x = pd.crosstab(pn.lessVal, pn.lessLev)
print('\n== H6-PN: valence x reward level of the LESS-observed option'); print(x); need((x.values == 8).all() and x.shape == (2, 2), 'H6-PN 8/8/8/8')
print('\n== Presentation balance'); print('High is A: %d/112; High on left: %d/112; H6 more-informed A: %d/64; Positive-is-A (PN): %d/48' % (
    (p.highOption == 'A').sum(), p.highLeft.sum(), (h6.moreInformativeOption == 'A').sum(), (p[p.valenceCondition == 'PN'].optionAValence == 'Positive').sum()))
need((p.highOption == 'A').sum() == 56 and p.highLeft.sum() == 56 and (h6.moreInformativeOption == 'A').sum() == 32, 'global A/B and side balance')
print('\n== Sections (games per section by horizon x valence)'); print(pd.crosstab(p.section, [p.horizon, p.valenceCondition]))
need(list(p.groupby('section').size()) == [16] * 7, '7 x 16')
h = list(p.horizon); run = best = 1
for i in range(1, 112):
    run = run + 1 if h[i] == h[i - 1] else 1; best = max(best, run)
print('\nmax run of same horizon: %d' % best); need(best <= 5, 'run limit')
print('\nAUDIT', 'PASS' if not fails else 'FAIL: ' + '; '.join(fails)); sys.exit(1 if fails else 0)
