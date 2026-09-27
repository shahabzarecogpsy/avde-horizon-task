function stim = avde_assign_stimuli_to_plan(plan, manifest, cfg, streamTag)
% Pre-generate every face image of every game (preview 2+2, and one outcome
% image for every possible free choice of each option). Constraints (strict;
% infeasibility aborts): valence matches the option; no identity twice within
% a game; image and identity not reused within minImageLagGames /
% minIdentityLagGames games; least-used candidate first with seeded random
% tie-breaking (spreads identities evenly across conditions).
if nargin < 4; streamTag = 'core'; end
seedKey = sprintf('%s|stim|%s|%s|%s', cfg.participantID, streamTag, plan(1).planID, strjoin({manifest.sha256},'|'));
oldRng = rng; restoreRng = onCleanup(@() rng(oldRng)); %#ok<NASGU>
rng(avde_seed_from_id(seedKey),'twister');
why = '';
for restart = 1:cfg.stim.maxAssignmentRestarts
    [stim, ok, why] = local_attempt(plan, manifest, cfg);
    if ok
        parts = cell(1,numel(stim));
        for g = 1:numel(stim)
            idx = [stim(g).previewA stim(g).previewB stim(g).outcomeA stim(g).outcomeB];
            parts{g} = sprintf('G%d:%s', stim(g).game, strjoin({manifest(idx).sha256},','));
        end
        h = avde_sha256_text(strjoin(parts,'|'));
        for g = 1:numel(stim); stim(g).stimulusMapID = ['SM' upper(h(1:16))]; end
        return;
    end
end
error('AVDE:StimulusScheduleInfeasible','No strict stimulus schedule after %d restarts: %s', cfg.stim.maxAssignmentRestarts, why);
end

function [stim, ok, why] = local_attempt(plan, manifest, cfg)
n = numel(manifest); stim = repmat(local_empty(), numel(plan), 1); ok = true; why = '';
usage = zeros(1,n); lastGame = -inf(1,n);
[uid,~,idOf] = unique({manifest.identityKey}); idLast = -inf(1,numel(uid));
isPos = strcmp({manifest.valenceClass},'Positive');
for g = 1:numel(plan)
    p = plan(g); s = local_empty(); s.game = p.game; used = false(1,numel(uid));
    spec = {'previewA',p.optionAValence,2; 'previewB',p.optionBValence,2; ...
            'outcomeA',p.optionAValence,p.horizon; 'outcomeB',p.optionBValence,p.horizon};
    for q = 1:size(spec,1)
        want = strcmp(spec{q,2},'Positive');
        picks = zeros(1,spec{q,3});
        for k = 1:spec{q,3}
            cand = find(isPos==want & ~used(idOf(:)') & (g-lastGame)>=cfg.stim.minImageLagGames & (g-idLast(idOf(:)'))>=cfg.stim.minIdentityLagGames);
            if isempty(cand); ok = false; why = sprintf('no %s candidate in game %d', spec{q,2}, g); return; end
            u = usage(cand); tied = cand(u==min(u)); pick = tied(randi(numel(tied)));
            picks(k) = pick; usage(pick) = usage(pick)+1; lastGame(pick) = g;
            idLast(idOf(pick)) = g; used(idOf(pick)) = true;
        end
        s.(spec{q,1}) = picks;
    end
    s.previewOrder = p.previewOrder; stim(g) = s;
end
end

function s = local_empty()
s = struct('game',NaN,'stimulusMapID','','previewA',[],'previewB',[],'outcomeA',[],'outcomeB',[],'previewOrder','');
end
