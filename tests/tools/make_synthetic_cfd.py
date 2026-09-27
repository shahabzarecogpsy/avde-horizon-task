"""Create a synthetic CFD-like folder (no real faces) for automated tests.
Filenames follow CFD-<race><gender>-<model>-<photo>-<expr>.jpg ; 149 identities
with both HC and A (the realistic count of CFD identities having both), plus
N-expression distractors and a few identities lacking A (must be excluded)."""
import os, sys, random
from PIL import Image
out = sys.argv[1]; os.makedirs(out, exist_ok=True)
random.seed(7)
strata = {'AF':18,'AM':18,'BF':30,'BM':28,'LF':15,'LM':14,'WF':14,'WM':12}
k = 0
for s, n in strata.items():
    sub = os.path.join(out, s); os.makedirs(sub, exist_ok=True)
    for i in range(1, n+1):
        k += 1
        for j, e in enumerate(['N','HC','A']):
            col = (random.randint(40,220), random.randint(40,220), random.randint(40,220))
            Image.new('RGB', (430, 600), col).save(os.path.join(sub, f'CFD-{s}-{i:03d}-{100+j:03d}-{e}.jpg'), quality=80)
# identities with HC only (must be excluded)
for i in range(1, 4):
    Image.new('RGB', (430, 600), (90,90,90)).save(os.path.join(out, 'WM', f'CFD-WM-{900+i:03d}-001-HC.jpg'))
print(k, 'identities')
