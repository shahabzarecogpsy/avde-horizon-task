"""Independent (Python, not MATLAB/Octave) check of the three reward 'gaps'.
1) latent gap: difference of the untruncated generating means (22 - 18 = 4).
2) displayed forced-sample gap: exactly 4 by construction (checked on exported events).
3) expected free-choice gap: E[round(X_H)] - E[round(X_L)], X ~ N(mu, 8) truncated to [1, 50]
   (truncate first, then round, exactly as the task does). Computed by exact
   numerical integration over the integer bins and by Monte Carlo."""
import math, random, sys
def phi(x): return math.exp(-x*x/2)/math.sqrt(2*math.pi)
def Phi(x): return 0.5*(1+math.erf(x/math.sqrt(2)))
def expected_rounded(mu, sd=8.0, lo=1.0, hi=50.0):
    Z = Phi((hi-mu)/sd) - Phi((lo-mu)/sd)
    e = 0.0
    for k in range(1, 51):
        a, b = max(lo, k-0.5), min(hi, k+0.5)
        if b <= a: continue
        pk = (Phi((b-mu)/sd) - Phi((a-mu)/sd))/Z
        e += k*pk
    return e
def truncated_mean(mu, sd=8.0, lo=1.0, hi=50.0):
    a, b = (lo-mu)/sd, (hi-mu)/sd; Z = Phi(b)-Phi(a)
    return mu + sd*(phi(a)-phi(b))/Z
eL, eH = expected_rounded(18), expected_rounded(22)
tL, tH = truncated_mean(18), truncated_mean(22)
random.seed(1); n = 400000
def draw(mu):
    while True:
        x = random.gauss(mu, 8)
        if 1 <= x <= 50: return int(math.floor(x+0.5))   # MATLAB round: half away from zero (x>0)
mcL = sum(draw(18) for _ in range(n))/n; mcH = sum(draw(22) for _ in range(n))/n
print('latent gap                     : %.4f' % (22-18))
print('truncated (continuous) means   : Low %.4f  High %.4f  gap %.4f' % (tL, tH, tH-tL))
print('expected rounded free draws    : Low %.4f  High %.4f  gap %.4f  (exact integration)' % (eL, eH, eH-eL))
print('Monte Carlo (n=%d)         : Low %.4f  High %.4f  gap %.4f' % (n, mcL, mcH, mcH-mcL))
if len(sys.argv) > 1:
    import csv
    rows = list(csv.DictReader(open(sys.argv[1], encoding='utf-8')))
    gaps = {}
    for r in rows:
        if r['eventType'] == 'forced_point':
            g = r['game']; lvl = r['optionARewardLevel'] if r['displayA'] != 'XX' else r['optionBRewardLevel']
            gaps.setdefault(g, {'High': [], 'Low': []})[lvl].append(float(r['reward']))
    d = [sum(v['High'])/len(v['High']) - sum(v['Low'])/len(v['Low']) for v in gaps.values()]
    print('displayed forced gap in %s: min %.6f max %.6f over %d games' % (sys.argv[1].split('/')[-1], min(d), max(d), len(d)))
