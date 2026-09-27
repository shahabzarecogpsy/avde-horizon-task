function pools = avde_partition_manifest(manifest, cfg)
% Disjoint identity pools: practice (both expressions) and core (valence-exclusive).
% Core allocation: each core identity is shown with exactly ONE expression for
% this participant. Allocation is stratified by race x gender (from filenames or
% local validation): within every stratum identities alternate between Positive
% and Negative in a seeded random order, so both classes have (near-)identical
% demographic composition. Remainders are balanced across strata.
seedKey = sprintf('%s|partition|%s', cfg.participantID, strjoin(sort({manifest.sha256}),'|'));
oldRng = rng; restoreRng = onCleanup(@() rng(oldRng)); %#ok<NASGU>
rng(avde_seed_from_id(seedKey),'twister');
ids = unique({manifest.identityKey});
need = cfg.stim.reservePracticeIdentities + sum(cfg.stim.minCoreIdentitiesPerClass);
if numel(ids) < need
    error('AVDE:StimulusBankTooSmall', ['Only %d identities have both a Positive (HC) and a Negative (A) image; ' ...
        'this design needs >= %d (%d practice + %d + %d core).'], numel(ids), need, cfg.stim.reservePracticeIdentities, cfg.stim.minCoreIdentitiesPerClass(1), cfg.stim.minCoreIdentitiesPerClass(2));
end
strat = cell(size(ids));
for k = 1:numel(ids)
    j = find(strcmp({manifest.identityKey},ids{k}),1);
    strat{k} = [manifest(j).race manifest(j).gender];
end
% practice identities: stratified random draw proportional to strata
nP = cfg.stim.reservePracticeIdentities;
ord = randperm(numel(ids)); ids = ids(ord); strat = strat(ord);
[~,~,sIdx] = unique(strat); sIdx = sIdx(:)';
practice = false(size(ids));
% round-robin over strata in random stratum order until nP chosen
sOrder = randperm(max(sIdx));
while sum(practice) < nP
    before = sum(practice);
    for s = sOrder
        cand = find(sIdx==s & ~practice);
        if ~isempty(cand) && sum(practice) < nP; practice(cand(1)) = true; end
    end
    if sum(practice) == before; error('AVDE:StimulusPartition','Practice identity reservation made no progress.'); end
end
coreIDs = ids(~practice); coreStrat = strat(~practice);
minCore = sum(cfg.stim.minCoreIdentitiesPerClass);
if numel(coreIDs) < minCore
    error('AVDE:StimulusPartition','Only %d core identities with HC and A; need >= %d.',numel(coreIDs),minCore);
end
% stratified alternating allocation
assign = cell(size(coreIDs));
[us,~,cs] = unique(coreStrat); cs = cs(:)';
startClass = randi(2); classes = {'Positive','Negative'};
for s = randperm(numel(us))
    members = find(cs==s); members = members(randperm(numel(members)));
    for m = 1:numel(members)
        assign{members(m)} = classes{1+mod(startClass+m,2)};
    end
    if mod(numel(members),2)==1; startClass = 3-startClass; end   % alternate the odd remainder across strata
end
core = repmat(avde_empty_manifest_row(),0,1);
for k = 1:numel(coreIDs)
    j = find(strcmp({manifest.identityKey},coreIDs{k}) & strcmp({manifest.valenceClass},assign{k}));
    assert(numel(j)==1,'AVDE:StimulusPartition','Identity %s lacks a unique %s image.',coreIDs{k},assign{k});
    m = manifest(j); m.assignedCoreValence = assign{k}; core(end+1,1) = m; %#ok<AGROW>
end
nPos = sum(strcmp({core.valenceClass},'Positive')); nNeg = sum(strcmp({core.valenceClass},'Negative'));
if nPos < cfg.stim.minCoreIdentitiesPerClass(1) || nNeg < cfg.stim.minCoreIdentitiesPerClass(2)
    error('AVDE:CoreIdentityAllocation','Core classes too small (Positive %d, Negative %d).',nPos,nNeg);
end
pools.practice = manifest(ismember({manifest.identityKey}, ids(practice)));
pools.core = core;
pools.coreStrataTable = local_strata_table(core);
end

function T = local_strata_table(core)
st = unique(strcat({core.race},{core.gender}));
T = struct('stratum',st,'positive',0,'negative',0);
for k = 1:numel(st)
    m = strcmp(strcat({core.race},{core.gender}),st{k});
    T(k).positive = sum(m & strcmp({core.valenceClass},'Positive'));
    T(k).negative = sum(m & strcmp({core.valenceClass},'Negative'));
end
end
