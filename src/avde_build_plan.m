function plan = avde_build_plan(cfg)
% AVDE v0.13.0 final-pilot plan generator (112 games, 7 sections x 16).
%
% DESIGN (fixed; validated exhaustively by avde_validate_plan):
%   H1 (Equal 2:2, 48 games): PP 16, NN 16, PN 16 (Positive=High 8 / Negative=High 8)
%   H6 (Unequal 3:1, 64 games): PP 16 (less-observed High 8 / Low 8)
%                               NN 16 (less-observed High 8 / Low 8)
%                               PN 32 (less-observed valence x reward = 8/8/8/8)
%
% CONSTRUCTION PRINCIPLE: the design is enumerated as 14 explicit "atoms" of
% 8 games. Every scientific factor (horizon, valence condition, reward level of
% the less-observed option, valence of the less-observed option, which PN
% option is High) is a property of the atom and is written literally; no factor
% is derived from another factor or from a shared parity/counterbalancing
% variable. Within each atom, three presentation factors (which internal label
% A/B is High, High screen side, which option is previewed first) form a full
% 2x2x2 factorial (one game per cell), and the forced-sample order is balanced
% orthogonally to each of them. Atoms are then distributed across the seven
% 16-game sections (one game per atom per section + one extra), and games are
% ordered within sections under run-length constraints.

oldRng=rng; restoreRng=onCleanup(@() rng(oldRng)); %#ok<NASGU>
rng(mod(cfg.plan.baseSeed + cfg.randomSeed, 2^32-1),'twister');

assert(cfg.task.nGames==112 && cfg.task.nSections==7 && cfg.task.gamesPerSection==16, 'AVDE:PlanConfig', ...
    'avde_build_plan implements exactly the 112-game / 7x16 final-pilot design.');

atoms = local_atoms();
nAtoms = numel(atoms);
rows = repmat(local_empty_planrow(), 0, 1);
for a = 1:nAtoms
    rows = [rows; local_expand_atom(atoms(a), a, cfg)]; %#ok<AGROW>
end
assert(numel(rows)==112,'AVDE:PlanConstruction');

% ---- distribute atoms over sections ------------------------------------
% Structural assignment (atom spread + horizon quotas) is exact by
% construction; presentation balance within sections is then optimized by a
% hill-climb that only swaps sections between two games of the SAME atom, so
% the structural quotas can never be violated by the optimizer.
F = local_section_features(rows);
best = local_assign_sections(rows, atoms); best = best(:)'; bestCost = local_section_cost(F, best);
for restart = 1:cfg.plan.maxSectionRestarts
    sec = local_assign_sections(rows, atoms);
    [sec, c] = local_hillclimb(F, sec, [rows.atomIndex], cfg.plan.hillClimbSteps);
    if c < bestCost; bestCost = c; best = sec; end
    if bestCost == 0; break; end
end
if isfield(cfg.plan,'verbose') && cfg.plan.verbose
    fprintf('section balance: restarts=%d residual cost=%g\n',restart,bestCost);
end
for i = 1:numel(rows); rows(i).section = best(i); end

% ---- order within sections ----------------------------------------------
plan = repmat(local_empty_planrow(), 0, 1);
for s = 1:cfg.task.nSections
    idx = find([rows.section]==s);
    ord = local_order_section(rows(idx), cfg, plan);   % run limits hold across section boundaries too
    plan = [plan; rows(idx(ord))]; %#ok<AGROW>
end
for g = 1:numel(plan)
    plan(g).game = g;
    plan(g).sectionPosition = g - (plan(g).section-1)*cfg.task.gamesPerSection;
end
h = avde_plan_hash(plan);
for g = 1:numel(plan); plan(g).planID = ['P' upper(h(1:12))]; end
end

% =========================================================================
function atoms = local_atoms()
% Literal enumeration of the 14 design atoms (8 games each).
% lowVal/highVal: valence of the Low / High option.
% lessObs: 'Equal' (H1) or 'High'/'Low' (H6: reward level of the less-observed option).
A = struct('id',{},'horizon',{},'vc',{},'lowVal',{},'highVal',{},'lessObs',{});
A(end+1)=struct('id','H1_PP_a','horizon',1,'vc','PP','lowVal','Positive','highVal','Positive','lessObs','Equal');
A(end+1)=struct('id','H1_PP_b','horizon',1,'vc','PP','lowVal','Positive','highVal','Positive','lessObs','Equal');
A(end+1)=struct('id','H1_NN_a','horizon',1,'vc','NN','lowVal','Negative','highVal','Negative','lessObs','Equal');
A(end+1)=struct('id','H1_NN_b','horizon',1,'vc','NN','lowVal','Negative','highVal','Negative','lessObs','Equal');
A(end+1)=struct('id','H1_PN_PosHigh','horizon',1,'vc','PN','lowVal','Negative','highVal','Positive','lessObs','Equal');
A(end+1)=struct('id','H1_PN_NegHigh','horizon',1,'vc','PN','lowVal','Positive','highVal','Negative','lessObs','Equal');
A(end+1)=struct('id','H6_PP_LessHigh','horizon',6,'vc','PP','lowVal','Positive','highVal','Positive','lessObs','High');
A(end+1)=struct('id','H6_PP_LessLow','horizon',6,'vc','PP','lowVal','Positive','highVal','Positive','lessObs','Low');
A(end+1)=struct('id','H6_NN_LessHigh','horizon',6,'vc','NN','lowVal','Negative','highVal','Negative','lessObs','High');
A(end+1)=struct('id','H6_NN_LessLow','horizon',6,'vc','NN','lowVal','Negative','highVal','Negative','lessObs','Low');
% H6-PN: less-observed valence x less-observed reward level (8/8/8/8)
A(end+1)=struct('id','H6_PN_LessNeg_LessHigh','horizon',6,'vc','PN','lowVal','Positive','highVal','Negative','lessObs','High');
A(end+1)=struct('id','H6_PN_LessNeg_LessLow', 'horizon',6,'vc','PN','lowVal','Negative','highVal','Positive','lessObs','Low');
A(end+1)=struct('id','H6_PN_LessPos_LessHigh','horizon',6,'vc','PN','lowVal','Negative','highVal','Positive','lessObs','High');
A(end+1)=struct('id','H6_PN_LessPos_LessLow', 'horizon',6,'vc','PN','lowVal','Positive','highVal','Negative','lessObs','Low');
atoms = A;
end

function R = local_expand_atom(atom, atomIndex, cfg)
% 8 games = full 2x2x2 factorial of (High is A, High on left, High previewed first),
% with forced-order classes assigned via XOR codes so that each class occurs
% twice and is marginally independent of each factorial factor.
[x1,x2,x3] = ndgrid([0 1],[0 1],[0 1]); X = [x1(:) x2(:) x3(:)];
roles = randperm(3);                     % random mapping of factors to columns
highIsA = X(:,roles(1)); highLeft = X(:,roles(2)); previewHighFirst = X(:,roles(3));
f1 = xor(X(:,1),X(:,2)); f2 = xor(X(:,1),X(:,3));
code = 2*f1 + f2;                        % 0..3, each exactly twice
codeMap = randperm(4)-1;                 % random bijection code -> order class
cls = codeMap(code+1);
R = repmat(local_empty_planrow(),8,1);
% H1 order classes (in High/Low letters): class 0 -> HLLH, 1 -> LHHL,
% 2 -> {HHLL,HLHL} (first High, last Low), 3 -> {LHLH,LLHH} (first Low, last High).
mixedPick = {randperm(2), randperm(2)}; mixedCounter = [0 0];
for k = 1:8
    spec = struct('atomID',atom.id,'atomIndex',atomIndex,'horizon',atom.horizon,'vc',atom.vc, ...
        'lowVal',atom.lowVal,'highVal',atom.highVal,'lessObs',atom.lessObs, ...
        'highIsA',logical(highIsA(k)),'highLeft',logical(highLeft(k)),'previewHighFirst',logical(previewHighFirst(k)), ...
        'forcedOrderHL','');
    if atom.horizon == 1
        switch cls(k)
            case 0; hl = 'HLLH';
            case 1; hl = 'LHHL';
            case 2; mixedCounter(1)=mixedCounter(1)+1; opts={'HHLL','HLHL'}; hl = opts{mixedPick{1}(mixedCounter(1))};
            case 3; mixedCounter(2)=mixedCounter(2)+1; opts={'LHLH','LLHH'}; hl = opts{mixedPick{2}(mixedCounter(2))};
        end
    else
        pos = cls(k) + 1;                   % position (1..4) of the single less-observed sample
        if strcmp(atom.lessObs,'High'); hl = 'LLLL'; hl(pos) = 'H'; else; hl = 'HHHH'; hl(pos) = 'L'; end
    end
    spec.forcedOrderHL = hl;
    R(k) = avde_make_game_row(spec, cfg);
end
R = R(randperm(8));
end

function sec = local_assign_sections(rows, atoms)
% Each atom contributes one game to every section plus one extra game.
% Extras: six sections receive one H1 extra and one H6 extra; the remaining
% section receives two H6 extras (=> H1 per section 7,7,7,7,7,7,6; H6 9,...,9,10).
nS = 7; sec = zeros(numel(rows),1);
h1Atoms = find([atoms.horizon]==1); h6Atoms = find([atoms.horizon]==6);
s0 = randi(nS); others = setdiff(1:nS, s0); others = others(randperm(numel(others)));
extraSec = zeros(1,numel(atoms));
extraSec(h1Atoms(randperm(numel(h1Atoms)))) = others;              % 6 H1 atoms -> 6 sections
h6perm = h6Atoms(randperm(numel(h6Atoms)));
extraSec(h6perm(1:6)) = others(randperm(6));                       % 6 H6 atoms -> same 6 sections
extraSec(h6perm(7:8)) = s0;                                         % 2 H6 atoms -> section s0
for a = 1:numel(atoms)
    idx = find([rows.atomIndex]==a); idx = idx(randperm(numel(idx)));
    target = [1:nS extraSec(a)]; target = target(randperm(numel(target)));
    sec(idx) = target;
end
end

function F = local_section_features(rows)
F.hiL = double(strcmp({rows.leftSource},{rows.highOption}))';
F.hiA = double(strcmp({rows.highOption},'A'))';
F.pvH = double(strcmp({rows.previewFirstSource},{rows.highOption}))';
F.isH6 = double([rows.horizon]==6)';
F.lessL = double(strcmp({rows.leftSource},{rows.lessInformativeOption}))' .* F.isH6;
F.isPN = double(strcmp({rows.valenceCondition},'PN'))';
F.posL = double(strcmp({rows.leftValence},'Positive'))' .* F.isPN;
end

function c = local_section_cost(F, sec)
% Presentation balance within each 16-game section (0 = perfect).
c = sum(local_cost_by_section(F, sec));
end

function cs = local_cost_by_section(F, sec)
cs = zeros(1,7);
for s = 1:7; cs(s) = local_one_section_cost(F, sec==s); end
end

function c = local_one_section_cost(F, m)
n = sum(m);
c = abs(2*sum(F.hiL(m))-n) + abs(2*sum(F.hiA(m))-n) + abs(2*sum(F.pvH(m))-n);
n6 = sum(F.isH6(m)); if n6>0; c = c + max(0, abs(2*sum(F.lessL(m))-n6)-1); end
np = sum(F.isPN(m)); if np>0; c = c + max(0, abs(2*sum(F.posL(m))-np)-1); end
end

function [sec, c] = local_hillclimb(F, sec, atomIndex, nSteps)
% Swap moves only between two games of the same atom; incremental cost.
sec = sec(:)'; cs = local_cost_by_section(F, sec); c = sum(cs);
n = numel(sec);
for step = 1:nSteps
    if c == 0; return; end
    i = randi(n); same = find(atomIndex==atomIndex(i) & sec~=sec(i));
    if isempty(same); continue; end
    j = same(randi(numel(same)));
    si = sec(i); sj = sec(j);
    trial = sec; trial([i j]) = [sj si];
    ci = local_one_section_cost(F, trial==si); cj = local_one_section_cost(F, trial==sj);
    delta = ci + cj - cs(si) - cs(sj);
    if delta <= 0
        sec = trial; cs(si) = ci; cs(sj) = cj; c = c + delta;
    end
end
end

function ord = local_order_section(r, cfg, before)
n = numel(r);
if isempty(before); hb = []; vb = {}; else; hb = [before.horizon]; vb = {before.valenceCondition}; end
for attempt = 1:5000
    ord = randperm(n);
    h = [hb r(ord).horizon]; v = [vb {r(ord).valenceCondition}];
    if local_maxrun(h) <= cfg.plan.maxRunSameHorizon && local_maxrun_cell(v) <= cfg.plan.maxRunSameValenceCondition
        return;
    end
end
error('AVDE:PlanOrdering','Could not order a section under the run-length constraints.');
end
function m = local_maxrun(x)
m = 1; cur = 1;
for i = 2:numel(x); if x(i)==x(i-1); cur = cur+1; m = max(m,cur); else; cur = 1; end; end
end
function m = local_maxrun_cell(x)
m = 1; cur = 1;
for i = 2:numel(x); if strcmp(x{i},x{i-1}); cur = cur+1; m = max(m,cur); else; cur = 1; end; end
end

function r = local_empty_planrow()
r = avde_empty_planrow();
end
