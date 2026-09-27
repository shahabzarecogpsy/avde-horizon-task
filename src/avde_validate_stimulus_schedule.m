function rep = avde_validate_stimulus_schedule(plan, stim, manifest, cfg)
% Independent re-check of the pre-generated face schedule. Throws on violation.
% "Planned" lags use every pre-assigned image (a superset of what can be shown),
% so the realized lags during the task can only be >= these.
assert(numel(stim)==numel(plan),'AVDE:StimCount','One stimulus map per game.');
lastImg = containers.Map('KeyType','char','ValueType','double');
lastId = containers.Map('KeyType','char','ValueType','double');
minImg = Inf; minId = Inf;
for g = 1:numel(plan)
    p = plan(g); s = stim(g);
    assert(numel(s.previewA)==2 && numel(s.previewB)==2 && numel(s.outcomeA)==p.horizon && numel(s.outcomeB)==p.horizon, 'AVDE:StimShape','Stimulus counts in game %d.',g);
    for o = 'AB'
        idx = [s.(['preview' o]) s.(['outcome' o])];
        assert(all(strcmp({manifest(idx).valenceClass}, p.(['option' o 'Valence']))), 'AVDE:StimValence','Valence mismatch in game %d.',g);
    end
    all_ = [s.previewA s.previewB s.outcomeA s.outcomeB];
    ids = {manifest(all_).identityKey};
    assert(numel(unique(ids))==numel(ids),'AVDE:StimWithinGame','Identity repeated within game %d.',g);
    for k = 1:numel(all_)
        f = manifest(all_(k)).file; i = ids{k};
        if isKey(lastImg,f); minImg = min(minImg, g-lastImg(f)); end
        if isKey(lastId,i); minId = min(minId, g-lastId(i)); end
    end
    for k = 1:numel(all_); lastImg(manifest(all_(k)).file) = g; lastId(ids{k}) = g; end
    assert(isequal(p.previewOrder, s.previewOrder),'AVDE:StimPreviewOrder','Preview order mismatch in game %d.',g);
end
assert(minImg >= cfg.stim.minImageLagGames && minId >= cfg.stim.minIdentityLagGames,'AVDE:StimLag','Lag constraint violated.');
rep = struct('minPlannedImageLag',minImg,'minPlannedIdentityLag',minId,'nImages',numel(unique([stim.previewA stim.previewB stim.outcomeA stim.outcomeB])));
end
